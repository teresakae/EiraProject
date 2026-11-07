import OpenAI from 'openai';
import { readFile } from 'node:fs/promises';
import { models, limits } from '../config.js';
import { askSchema, draftSchema, extractSchema, requestSchemas, talkSchema } from './schemas.js';
import { normalize, quoteFound } from './quote-check.js';
import { requireInput, AppError } from './validation.js';
import { loadFAQ } from './faq.js';
import { runText } from './model.js';

const promptFile = (name) => readFile(new URL(`../prompts/${name}.txt`, import.meta.url), 'utf8');
const privateTaskWords = /\b(?:i|me|my|husband|wife|family|child|children|mother|father|friend|neighbour|neighbor|police|law|legal|help|abuse|violence|bruise|bruised|blood|hurt|hit|fear|afraid|sad|angry|money|report|reporting|you|your|she|her|he|his|they|them|we|our|eira|kdrt|sapa|lapor\w*|suami\w*|istri\w*|anak\w*|ibu|ayah|bapak|mama|papa|adik|kakak|dimas|keluarga|teman|tetangga|orang|menangis|nangis|sedih|takut|marah|mabuk|pukul\w*|tampar\w*|memar|bengkak|sakit|darah|kekerasan|uang|belanja|polisi|hukum|bantuan|lbh|api[k]?|uptd|perasaan|kamu|aku|dia|nya)\b/iu;
// Talk never carries law or a verdict; legal questions go through ask and its approved FAQ.
const talkLawWords = /\b(?:pasal|undang-undang|uu\s*\d+|article\s+\d+|statute|penalt(?:y|ies)|sentence[ds]?|jail|prison|perpetrator|guilty|crime|criminal|pelaku|tindak pidana)\b/iu;

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

// ponytail: keyword match. A question mixing arrest with another topic goes to the model; add words here if one slips through.
export function isArrestQuestion(question) {
  return /\b(arrest\w*|ditangkap|menangkap|tangkap)\b/iu.test(question)
    && /\b(husband|he|him|suami\w*|dia)\b/iu.test(question)
    && !/\b(kids?|child\w*|anak\w*|pay\w*|money|uang|protection|order|custody|divorce|cerai|jail|prison|penjara|withdraw\w*|cabut)\b/iu.test(question);
}

export function safeCoverTask(title, entry) {
  return coverTaskProblem(title, entry) === null;
}

// She may write in Indonesian or English (C14); concern must be stated in her own words either way.
const concernWords = {
  sedikit_khawatir: ['sedikit khawatir', 'a little worried', 'a little concerned'],
  khawatir: ['khawatir', 'worried', 'concerned'],
  sangat_khawatir: ['sangat khawatir', 'very worried', 'very concerned'],
};

export function checkedDraft(draft, sources) {
  for (const [name, pair] of Object.entries(draft)) {
    const noSource = pair.value === null || !sources.some((text) => quoteFound(pair.quote, text));
    const badAge = name === 'korban_age' && (pair.value < 1 || pair.value > 100);
    const badNumber = ['korban_contact_number', 'korban_trusted_person', 'contact_number'].includes(name)
      && pair.value !== null && !/^\d+$/u.test(pair.value);
    const badText = typeof pair.value === 'string' && (!pair.value.trim() || [...pair.value].length > 5000);
    const unknownTime = name === 'incident_time' && pair.value === 'Tidak Diketahui';
    const inferredConcern = name === 'level_concern' && pair.value !== null
      && !(concernWords[pair.value] ?? []).some((words) => quoteFound(words, pair.quote || ''));
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
      if (!process.env.OPENAI_API_KEY) throw new AppError(503, 'server_not_configured', 'I cannot process this right now.');
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
      const output = await textCall('extract', input, extractSchema, (result) => {
        const issue = coverTaskProblem(result.cover_task, input.text) || (!result.reply.trim() ? 'empty_reply' : null);
        if (issue) throw Object.assign(new Error('Invalid extract output'), { outputIssue: issue });
        result.events = result.events.filter((event) => quoteFound(event.quote, input.text));
        return result;
      });
      // ponytail: the model repeats itself across entries and sees only one, so plain code picks the title. Random and stateless, so an occasional repeat happens; a longer list lowers it.
      const titles = (await promptFile('cover_titles')).split('\n').map((title) => title.trim()).filter((title) => safeCoverTask(title, input.text));
      if (titles.length) output.cover_task = titles[Math.floor(Math.random() * titles.length)];
      return output;
    },
    async ask(input) {
      requireInput(input, requestSchemas.ask, 'ask');
      const faq = await faqLoader();
      if (faq.length === 0) return handoff();
      // C27: the arrest fear gets one fixed answer from approved FAQ answer 1, with no model wording.
      if (isArrestQuestion(input.question) && faq.some((answer) => answer.number === 1)) {
        return { answer: (await promptFile('arrest_answer')).trim(), faq_answers_used: [1], articles_named: [], not_sure: false };
      }
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
    async talk(input) {
      requireInput(input, requestSchemas.talk, 'talk');
      const herWords = [
        ...input.entries.map((entry) => entry.text),
        ...input.conversation.filter((turn) => turn.role === 'user').map((turn) => turn.text),
        ...(input.message ? [input.message] : []),
      ];
      return textCall('talk', input, talkSchema, (result) => {
        if (!result.is_legal_question && (!result.reply.trim() || talkLawWords.test(result.reply))) {
          throw Object.assign(new Error('Invalid talk output'), { outputIssue: 'talk_reply' });
        }
        result.quick_replies = result.quick_replies
          .map((reply) => reply.trim())
          .filter((reply) => reply && reply.length <= 40 && !talkLawWords.test(reply))
          .slice(0, 2);
        result.facts = result.facts.filter((fact) => fact.value.trim()
          && herWords.some((source) => quoteFound(fact.quote, source)));
        return result;
      });
    },
    async draft(input) {
      requireInput(input, requestSchemas.draft, 'draft');
      return textCall('draft', input, draftSchema, (result) => checkedDraft(result, [...input.entries, ...input.questions]));
    },
    async transcribe(file) {
      const extension = file?.name?.split('.').at(-1)?.toLowerCase();
      if (!(file instanceof File) || !['mp3', 'mp4', 'mpeg', 'mpga', 'm4a', 'wav', 'webm'].includes(extension) || file.size === 0) {
        throw new AppError(400, 'invalid_audio', 'This recording could not be read.');
      }
      if (file.size > limits.audioBytes) throw new AppError(413, 'audio_too_large', 'The recording exceeds the 4 MB limit.');
      // Memory only, with a neutral filename. No upload to the Files API or disk.
      const audio = new File([file], `audio.${extension}`, { type: file.type });
      const response = await getClient().audio.transcriptions.create({
        file: audio, model: modelConfig.transcribe, languages: ['id', 'en'], response_format: 'json',
      });
      if (typeof response.text !== 'string' || !response.text.trim()) {
        throw new AppError(502, 'transcription_unavailable', 'The recording could not be transcribed.');
      }
      return { text: response.text };
    },
  };
}
