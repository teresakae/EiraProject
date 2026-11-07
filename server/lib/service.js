import OpenAI from 'openai';
import { readFile } from 'node:fs/promises';
import { models, limits } from '../config.js';
import { askSchema, draftSchema, extractSchema, requestSchemas } from './schemas.js';
import { normalize, quoteFound } from './quote-check.js';
import { requireInput, AppError } from './validation.js';
import { loadFAQ } from './faq.js';
import { runText } from './model.js';

const promptFile = (name) => readFile(new URL(`../prompts/${name}.txt`, import.meta.url), 'utf8');
const privateTaskWords = /\b(?:eira|kdrt|sapa|lapor\w*|suami\w*|istri\w*|anak\w*|ibu|ayah|bapak|mama|papa|adik|kakak|dimas|keluarga|teman|tetangga|orang|menangis|nangis|sedih|takut|marah|mabuk|pukul\w*|tampar\w*|memar|bengkak|sakit|darah|kekerasan|uang|belanja|polisi|hukum|bantuan|lbh|api[k]?|uptd|perasaan|kamu|aku|dia|nya)\b/iu;

function coverTaskProblem(title, entry) {
  if (!title.trim() || title.length > 80) return 'task_length';
  if (!/^[\p{L} ]+[.!]?$/u.test(title.trim())) return 'task_characters';
  if (privateTaskWords.test(title)) return 'task_private_word';
  const words = normalize(title).split(' ');
  if (words.length < 2 || words.length > 6) return 'task_word_count';
  // Reject content overlap as well as the reserved title and private vocabulary.
  const source = new Set(normalize(entry).split(' '));
  return words.some((word) => word.length > 2 && source.has(word)) ? 'task_source_overlap' : null;
}

export function safeCoverTask(title, entry) {
  return coverTaskProblem(title, entry) === null;
}

export function checkedDraft(draft, sources) {
  for (const [name, pair] of Object.entries(draft)) {
    const noSource = pair.value === null || !sources.some((text) => quoteFound(pair.quote, text));
    const badAge = name === 'korban_age' && (pair.value < 1 || pair.value > 100);
    const badNumber = ['korban_contact_number', 'korban_trusted_person', 'contact_number'].includes(name)
      && pair.value !== null && !/^\d+$/u.test(pair.value);
    const badText = typeof pair.value === 'string' && (!pair.value.trim() || [...pair.value].length > 5000);
    const unknownTime = name === 'incident_time' && pair.value === 'Tidak Diketahui';
    const inferredConcern = name === 'level_concern' && pair.value !== null
      && !quoteFound(pair.value.replaceAll('_', ' '), pair.quote || '');
    if (noSource || badAge || badNumber || badText || unknownTime || inferredConcern) {
      draft[name] = { value: null, quote: null };
    }
  }
  return draft;
}

export function createService({ client, faqLoader = loadFAQ, modelConfig = models, finding } = {}) {
  let sdk = client;
  let handoffIndex = 0;
  const getClient = () => {
    if (!sdk) {
      if (!process.env.OPENAI_API_KEY) throw new AppError(503, 'server_not_configured', 'Aku belum bisa memprosesnya sekarang.');
      sdk = new OpenAI({ apiKey: process.env.OPENAI_API_KEY, maxRetries: 0, timeout: 25_000, logLevel: 'off' });
    }
    return sdk;
  };
  const handoff = async () => {
    const lines = (await promptFile('handoff')).trim().split(/\r?\n/u);
    // Only an index is retained; no question, entry, or reply is kept.
    const answer = lines[handoffIndex++ % lines.length];
    return { answer, faq_answers_used: [], articles_named: [], not_sure: true };
  };
  const textCall = async (job, input, schema, validate) => {
    const [prompt, voice] = await Promise.all([promptFile(job), job === 'draft' ? '' : promptFile('voice')]);
    return runText({
      client: getClient(), job, prompt: `${prompt}\n${voice}`, input, schema, validate, finding,
      candidates: [job === 'draft' ? modelConfig.fallback : modelConfig.primary, modelConfig.fallback],
    });
  };
  return {
    async extract(input) {
      requireInput(input, requestSchemas.extract, 'extract');
      return textCall('extract', input, extractSchema, (result) => {
        const issue = coverTaskProblem(result.cover_task, input.text) || (!result.reply.trim() ? 'empty_reply' : null);
        if (issue) throw Object.assign(new Error('Invalid extract output'), { outputIssue: issue });
        result.events = result.events.filter((event) => quoteFound(event.quote, input.text));
        return result;
      });
    },
    async ask(input) {
      requireInput(input, requestSchemas.ask, 'ask');
      const faq = await faqLoader();
      if (faq.length === 0) return handoff();
      const schema = structuredClone(askSchema);
      schema.properties.faq_answers_used.items.enum = faq.map((answer) => answer.number);
      const result = await textCall('ask', { ...input, approved_faq: faq }, schema, (answer) => {
        const sources = faq.filter((item) => answer.faq_answers_used.includes(item.number));
        if (!answer.answer.trim() || answer.articles_named.some((article) => !article.trim()
          || !sources.some((source) => normalize(source.text).includes(normalize(article))))) {
          throw new Error('Unsupported article');
        }
        return answer;
      });
      if (result.faq_answers_used.length === 0) return handoff();
      result.faq_answers_used = [...new Set(result.faq_answers_used)];
      if (result.faq_answers_used.some((number) => [4, 7, 11].includes(number))) {
        result.answer += ` ${ (await promptFile('caveat')).trim() }`;
      }
      return result;
    },
    async draft(input) {
      requireInput(input, requestSchemas.draft, 'draft');
      return textCall('draft', input, draftSchema, (result) => checkedDraft(result, [...input.entries, ...input.questions]));
    },
    async transcribe(file) {
      const extension = file?.name?.split('.').at(-1)?.toLowerCase();
      if (!(file instanceof File) || !['mp3', 'mp4', 'mpeg', 'mpga', 'm4a', 'wav', 'webm'].includes(extension) || file.size === 0) {
        throw new AppError(400, 'invalid_audio', 'Rekaman ini belum bisa dibaca.');
      }
      if (file.size > limits.audioBytes) throw new AppError(413, 'audio_too_large', 'Rekamannya melebihi batas 4 MB.');
      // Memory only, with a neutral filename. No upload to the Files API or disk.
      const audio = new File([file], `audio.${extension}`, { type: file.type });
      const response = await getClient().audio.transcriptions.create({
        file: audio, model: modelConfig.transcribe, languages: ['id'], response_format: 'json',
      });
      if (typeof response.text !== 'string' || !response.text.trim()) {
        throw new AppError(502, 'transcription_unavailable', 'Rekamannya belum bisa aku ubah jadi teks.');
      }
      return { text: response.text };
    },
  };
}
