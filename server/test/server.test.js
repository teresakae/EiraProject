import test from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFile, readdir } from 'node:fs/promises';
import { checkedDraft, createService, isArrestQuestion, safeCoverTask } from '../lib/service.js';
import { endpoint } from '../lib/http.js';
import { parseFAQ, loadFAQ } from '../lib/faq.js';
import { quoteFound } from '../lib/quote-check.js';
import { runText } from '../lib/model.js';
import { askSchema, draftSchema, extractSchema, requestSchemas, fieldNames, talkSchema } from '../lib/schemas.js';
import { matches } from '../lib/validation.js';
import { M1, X5, testFAQ } from './fixtures.js';

const blankDraft = () => Object.fromEntries(fieldNames.map((name) => [name, { value: null, quote: null }]));
const handoffResult = { answer: 'Aku belum bisa menjawabnya.', faq_answers_used: [], articles_named: [], not_sure: true };
const extracted = () => ({ events: [{ when_text: 'Semalam sekitar jam 11', what_happened: 'Dia nampar pipi kiriku dua kali', injuries: 'Pipiku masih bengkak', witnesses: ['Dimas'], quote: 'Dia nampar pipi kiriku dua kali', pkdrt_type: 'fisik' }], cover_task: 'Rapikan meja', reply: 'Pipimu masih bengkak.' });
const completion = (value) => ({ status: 'completed', output: [{ type: 'message', content: [{ type: 'output_text', text: JSON.stringify(value) }] }] });
function fakeClient(sequence) {
  const calls = [];
  return { calls, responses: { async create(request) {
    calls.push(request);
    const value = sequence.shift();
    if (value instanceof Error) throw value;
    assert.ok(value, 'Unexpected extra model call');
    return value;
  } } };
}
const quiet = () => {};
const askInput = () => ({ question: 'Jadi suamiku itu pelaku KDRT, kan?', conversation: [], entries: [{ text: M1, events: [] }] });
const request = (body, options = {}) => new Request('http://localhost/api/extract', {
  method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer test-token', ...options.headers },
  body: JSON.stringify(body), ...options,
});

test('Schemas require every key, reject extras, and keep nullable properties explicit', () => {
  const visit = (schema) => {
    if (schema.type === 'object') {
      assert.equal(schema.additionalProperties, false);
      assert.deepEqual(schema.required, Object.keys(schema.properties));
      Object.values(schema.properties).forEach(visit);
    }
    if (schema.items) visit(schema.items);
  };
  [extractSchema, askSchema, talkSchema, draftSchema, ...Object.values(requestSchemas)].forEach(visit);
  assert.equal(fieldNames.length, 17);
  assert.ok(matches(blankDraft(), draftSchema));
  assert.ok(!matches({ text: M1, prompt: 'ignored' }, requestSchemas.extract));
  assert.ok(!matches(null, requestSchemas.extract));
});

test('Q1/Q2/Q3/Q6: quote check rejects invented, corrupted and empty quotes, accepts harmless changes', () => {
  assert.ok(quoteFound('PIPIKU MASIH BENGKAK', M1));
  assert.ok(quoteFound('suamiku pulang mabuk marah gara-gara nasi belum matang', M1));
  assert.ok(!quoteFound('Pipiku sudah bengkak', M1));
  assert.ok(!quoteFound('Suamiku bernama Budi', M1));
  assert.ok(!quoteFound('...?!', M1));
  assert.ok(quoteFound('ＡＢＣ “kata”', 'abc "kata"'));
});

test('P1: reject the reserved title, private sample and source overlap', () => {
  for (const title of ['eira', 'Eira', X5, 'Beli obat untuk Dimas', 'Beli uang belanja', 'Rapikan lemari']) {
    assert.ok(!safeCoverTask(title, M1), 'Unsafe task must be rejected');
  }
  assert.ok(safeCoverTask('Rapikan meja', M1));
});

test('FAQ loader excludes placeholders, metadata and empty slots; keeps multiline approved text', () => {
  const markdown = `${testFAQ([3])}\n## 4. Not approved\n\nApproved text: TO FILL IN\nSource: marker\nApproved by:\n`;
  const faq = parseFAQ(markdown);
  assert.deepEqual(faq.map((answer) => answer.number), [3]);
  assert.ok(!JSON.stringify(faq).includes('TO FILL IN'));
  assert.ok(!JSON.stringify(faq).includes('Source:'));
  assert.deepEqual(parseFAQ('## 1. Question\nApproved text:\nSource: source\nApproved by:\n'), []);
  assert.equal(parseFAQ('## 1. Question\nApproved text:\nFirst line.\nSecond line.\nSource: source\nApproved by:\n')[0].text, 'First line.\nSecond line.');
});

test('Every text call uses Responses, strict outputs, store:false, bounded output, and no person identifiers', async () => {
  const client = fakeClient([completion(extracted())]);
  await createService({ client, finding: quiet }).extract({ text: M1 });
  const call = client.calls[0];
  assert.equal(call.store, false);
  assert.equal(call.text.format.strict, true);
  assert.equal(call.reasoning.effort, 'none');
  assert.equal(call.model, 'gpt-6-luna');
  assert.ok(call.max_output_tokens > 0);
  for (const key of ['previous_response_id', 'user', 'safety_identifier', 'metadata', 'conversation']) assert.ok(!Object.hasOwn(call, key));
  assert.deepEqual(JSON.parse(call.input[0].content[0].text), { text: M1 });
});

test('Refusal checked before JSON: retry once, then try Terra; never return raw refusal', async () => {
  const refusal = { status: 'completed', output: [{ type: 'message', content: [{ type: 'output_text', text: '{bad json' }, { type: 'refusal', refusal: 'invented refusal test marker' }] }] };
  const client = fakeClient([refusal, refusal, completion(extracted())]);
  const findings = [];
  await createService({ client, finding: (finding) => findings.push(finding) }).extract({ text: M1 });
  assert.deepEqual(client.calls.map((call) => call.model), ['gpt-6-luna', 'gpt-6-luna', 'gpt-6.1-terra']);
  assert.equal(findings.filter((finding) => finding.kind === 'refusal').length, 2);
  assert.ok(!JSON.stringify(findings).includes('marker'));
});

test('Incomplete, malformed and API failures use the fallback and fail cleanly if both fail', async () => {
  for (const failure of [ { status: 'incomplete', output: [] }, completion({ wrong: true }), new Error('private SDK error marker') ]) {
    const client = fakeClient([failure, completion(extracted())]);
    await createService({ client, finding: quiet }).extract({ text: M1 });
    assert.deepEqual(client.calls.map((call) => call.model), ['gpt-6-luna', 'gpt-6.1-terra']);
  }
  const client = fakeClient([new Error('private'), new Error('private')]);
  await assert.rejects(createService({ client, finding: quiet }).extract({ text: M1 }), { code: 'model_unavailable', status: 502 });
});

test('Invalid extract quote is dropped; unsafe cover task retries fallback', async () => {
  const bad = extracted();
  bad.cover_task = X5;
  const good = extracted();
  good.events.push({ ...good.events[0], quote: 'invented source marker' });
  const client = fakeClient([completion(bad), completion(good)]);
  const result = await createService({ client, finding: quiet }).extract({ text: M1 });
  assert.equal(result.events.length, 1);
  assert.equal(client.calls.length, 2);
});

test('Q1/Q4/Q5: draft drops missing/invented quotes and inferred concern; questions are sources', async () => {
  const draft = blankDraft();
  draft.reporter_fullname = { value: 'invented name', quote: 'invented quotation' };
  draft.level_concern = { value: 'sangat_khawatir', quote: 'Pipiku masih bengkak' };
  draft.description = { value: 'Pipiku masih bengkak', quote: 'Pipiku masih bengkak' };
  draft.korban_age = { value: 200, quote: '9 th' };
  draft.incident_time = { value: 'Tidak Diketahui', quote: 'Semalam' };
  draft.korban_contact_number = { value: 'not-digits', quote: 'jam 11' };
  const client = fakeClient([completion(draft)]);
  const result = await createService({ client, finding: quiet }).draft({ entries: [], questions: [M1] });
  for (const name of ['reporter_fullname', 'level_concern', 'korban_age', 'incident_time', 'korban_contact_number']) assert.equal(result[name].value, null);
  assert.equal(result.description.quote, 'Pipiku masih bengkak');
  assert.equal(client.calls[0].model, 'gpt-6.1-terra');
  assert.equal(client.calls[0].store, false);
});

test('C27: arrest questions get the fixed FAQ 1 answer with no model call, only while answer 1 is approved', async () => {
  for (const question of ['If I report this, will my husband be arrested right away?', 'Wait, if i report this, would my husband get arrested?', 'Kalau aku lapor, apa suamiku langsung ditangkap?']) {
    assert.ok(isArrestQuestion(question), question);
  }
  for (const question of ['If he is arrested, who pays for the kids?', 'Can police arrest him if he breaks the protection order?', 'Do I need witnesses?']) {
    assert.ok(!isArrestQuestion(question), question);
  }
  const question = 'If I report this, will my husband be arrested right away?';
  const fixed = await createService({ faqLoader: async () => parseFAQ(testFAQ([1])), finding: quiet }).ask({ ...askInput(), question });
  assert.match(fixed.answer, /^No, not automatically\./);
  assert.deepEqual(fixed.faq_answers_used, [1]);
  const client = fakeClient([completion(handoffResult)]);
  const notApproved = await createService({ client, faqLoader: async () => parseFAQ(testFAQ([3])), finding: quiet }).ask({ ...askInput(), question });
  assert.deepEqual(notApproved.faq_answers_used, []);
});

test('FA1: unsupported Ask discards model answer; only approved slots enter the prompt', async () => {
  const client = fakeClient([completion({ ...handoffResult, answer: 'untrusted invented legal marker' })]);
  const app = createService({ client, faqLoader: async () => parseFAQ(testFAQ([3])), finding: quiet });
  const result = await app.ask(askInput());
  assert.ok(!result.answer.includes('marker'));
  assert.deepEqual(result.faq_answers_used, []);
  assert.ok(result.not_sure);
  const input = JSON.parse(client.calls[0].input[0].content[0].text);
  assert.deepEqual(input.approved_faq.map((answer) => answer.number), [3]);
});

test('Unknown FAQ number cannot survive strict validation; uses fallback', async () => {
  const client = fakeClient([completion({ ...handoffResult, faq_answers_used: [4] }), completion({ ...handoffResult, faq_answers_used: [3] })]);
  const result = await createService({ client, faqLoader: async () => parseFAQ(testFAQ([3])), finding: quiet }).ask(askInput());
  assert.deepEqual(result.faq_answers_used, [3]);
  assert.equal(client.calls.length, 2);
});

test('FA3: empty approved FAQ needs no OpenAI call and hands off; generic openings vary', async () => {
  const client = fakeClient([]);
  const app = createService({ client, faqLoader: async () => [], finding: quiet });
  const answers = [];
  for (let index = 0; index < 4; index += 1) {
    const result = await app.ask(askInput());
    assert.ok(result.answer.includes('LBH APIK'));
    assert.deepEqual(result.faq_answers_used, []);
    assert.deepEqual(result.articles_named, []);
    assert.ok(result.not_sure);
    answers.push(result.answer);
  }
  assert.ok(answers.slice(1).every((answer, index) => answer !== answers[index]));
  assert.equal(client.calls.length, 0);
});

test('V1: plain code appends caveat for slots 4, 7 and 11', async () => {
  for (const number of [4, 7, 11]) {
    const client = fakeClient([completion({ ...handoffResult, faq_answers_used: [number] })]);
    const result = await createService({ client, faqLoader: async () => parseFAQ(testFAQ([number])), finding: quiet }).ask(askInput());
    assert.ok(result.answer.endsWith('This part has not been reviewed by a lawyer.'));
  }
});

test('Unsupported article cannot survive; no article map is supplied as independent grounding', async () => {
  const client = fakeClient([completion({ ...handoffResult, faq_answers_used: [3], articles_named: ['Pasal 9999'] }), completion({ ...handoffResult, faq_answers_used: [3], articles_named: ['Pasal 6'] })]);
  const result = await createService({ client, faqLoader: async () => parseFAQ(testFAQ([3])), finding: quiet }).ask(askInput());
  assert.deepEqual(result.articles_named, ['Pasal 6']);
});

test('HTTP authentication, POST only, invalid bodies and unknown prompt/schema keys', async () => {
  let called = 0;
  const fetch = endpoint('extract', { token: () => 'test-token', app: { extract: async () => { called += 1; return extracted(); } } });
  assert.equal((await fetch(new Request('http://localhost', { method: 'GET' }))).status, 405);
  assert.equal((await fetch(request({ text: M1 }, { headers: { 'Content-Type': 'application/json' } }))).status, 401);
  assert.equal((await fetch(new Request('http://localhost', { method: 'POST', headers: { Authorization: 'Bearer test-token', 'Content-Type': 'application/json' }, body: '{' }))).status, 400);
  const response = await fetch(request({ text: M1 }));
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.equal(called, 1);
  const app = createService({ client: fakeClient([]), finding: quiet });
  await assert.rejects(app.extract({ text: M1, instructions: 'override' }), { status: 400 });
  await assert.rejects(app.extract({ text: '' }), { status: 400 });
  await assert.rejects(app.ask({ ...askInput(), entries: [{ text: M1, events: [], id: 'person-id' }] }), { status: 400 });
});

test('HTTP failures return clean errors with no SDK response text', async () => {
  const fetch = endpoint('extract', { token: () => 'test-token', app: { extract: async () => { throw new Error('private body marker'); } } });
  const response = await fetch(request({ text: M1 }));
  assert.equal(response.status, 502);
  assert.ok(!(await response.text()).includes('marker'));
});

test('Audio: in-memory multipart only, 4 MB limit, formats, Indonesian/English languages, neutral filename', async () => {
  const calls = [];
  const app = createService({ client: { audio: { transcriptions: { async create(input) { calls.push(input); return { text: 'teks rekaan' }; } } } } });
  const form = new FormData();
  form.set('file', new File(['invented audio bytes'], 'private-name.m4a', { type: 'audio/mp4' }));
  form.set('language', 'id');
  const fetch = endpoint('transcribe', { token: () => 'test-token', app });
  const response = await fetch(new Request('http://localhost', { method: 'POST', headers: { Authorization: 'Bearer test-token' }, body: form }));
  assert.equal(response.status, 200);
  assert.equal(calls[0].file.name, 'audio.m4a');
  assert.deepEqual(calls[0].languages, ['id', 'en']);
  assert.ok(!Object.hasOwn(calls[0], 'language'));
  assert.equal(calls[0].model, 'gpt-transcribe');
  assert.ok(!Object.hasOwn(calls[0], 'store'));
  await assert.rejects(app.transcribe(new File([new Uint8Array(4_000_001)], 'audio.m4a')), { status: 413 });
  await assert.rejects(app.transcribe(new File(['x'], 'audio.txt')), { status: 400 });
  await assert.rejects(app.transcribe(new File([], 'audio.m4a')), { status: 400 });
  const failing = createService({ client: { audio: { transcriptions: { async create() { throw new Error('private audio marker'); } } } } });
  const failure = endpoint('transcribe', { token: () => 'test-token', app: failing });
  const failed = await failure(new Request('http://localhost', { method: 'POST', headers: { Authorization: 'Bearer test-token' }, body: form }));
  assert.equal(failed.status, 502);
  assert.ok(!(await failed.text()).includes('marker'));
});

test('FA2: build and runtime use an explicit server allowlist and the approved FAQ only', async () => {
  execFileSync(process.execPath, ['scripts/build.js'], { cwd: new URL('../', import.meta.url), stdio: 'pipe' });
  const root = new URL('../dist/', import.meta.url);
  const walk = async (directory) => {
    for (const entry of await readdir(directory, { withFileTypes: true })) {
      const path = new URL(entry.name + (entry.isDirectory() ? '/' : ''), directory);
      if (entry.isDirectory()) { await walk(path); continue; }
      assert.ok(!/LEGAL_(?:FAQ|REVIEW_LOG)/u.test(entry.name));
      const content = await readFile(path, 'utf8');
      assert.ok(!/LEGAL_(?:FAQ|REVIEW_LOG)\.md/u.test(content));
      assert.ok(!/OPENAI_API_KEY=sk-/u.test(content));
    }
  };
  await walk(root);
  assert.deepEqual(parseFAQ(await readFile(new URL('data/FAQ_APPROVED.md', root), 'utf8')), await loadFAQ());
  const entries = await readdir(root);
  assert.ok(!entries.includes('.env.local'));
  assert.ok(!entries.includes('test'));
});


test('English output keeps original sources, enum values and privacy boundaries', async () => {
  const voice = await readFile(new URL('../prompts/voice.txt', import.meta.url), 'utf8');
  const draft = await readFile(new URL('../prompts/draft.txt', import.meta.url), 'utf8');
  assert.match(voice, /Every reply she reads is English/);
  assert.match(draft, /Preserve every source quote exactly/);
  assert.match(draft, /Write description in Indonesian, in the first person/);
  assert.match(draft, /relationship_with_victim is how the person who did it is related to the\s+victim/);
  const app = createService({ faqLoader: async () => [] });
  const response = await app.ask(askInput());
  assert.match(response.answer, /cannot answer|do not have an answer/);
  assert.deepEqual(response.faq_answers_used, []);
  assert.equal(safeCoverTask('Call your husband', M1), false);
  assert.equal(safeCoverTask('Find legal help', M1), false);
  assert.equal(safeCoverTask('Water the fern', M1), true);
  const stated = "I'm very worried.";
  const concern = (value, quote) => checkedDraft({ level_concern: { value, quote } }, [stated]).level_concern.value;
  assert.equal(concern('sangat_khawatir', stated), 'sangat_khawatir');
  assert.equal(concern('sedikit_khawatir', stated), null);
  const titles = (await readFile(new URL('../prompts/cover_titles.txt', import.meta.url), 'utf8')).trim().split('\n');
  assert.ok(titles.length >= 30 && new Set(titles).size === titles.length, 'Cover titles are varied');
  for (const title of titles) assert.ok(safeCoverTask(title, 'x'), `Unsafe cover title: ${title}`);
});

const talkInput = (message = 'Dia atasanku di kantor.') => ({ message, conversation: [], entries: [{ text: M1, events: [] }] });
const talked = (overrides = {}) => ({ reply: 'Has this happened before?', is_legal_question: false, quick_replies: [], facts: [], ...overrides });

test('Talk uses store:false and keeps only facts quoted from her words', async () => {
  const client = fakeClient([completion(talked({ facts: [
    { category: 'who', value: 'her supervisor', quote: 'atasanku' },
    { category: 'where', value: 'invented place', quote: 'di gudang kantor' },
    { category: 'who', value: 'from AI text', quote: 'Has this happened' },
  ] }))]);
  const result = await createService({ client, finding: quiet }).talk({
    ...talkInput(), conversation: [{ role: 'assistant', text: 'Has this happened' }],
  });
  assert.equal(client.calls[0].store, false);
  assert.deepEqual(result.facts.map((fact) => fact.value), ['her supervisor']);
});

test('Talk rejects a reply carrying law, then falls back; never returns it', async () => {
  const client = fakeClient([
    completion(talked({ reply: 'That fits Pasal 6. Has it happened before?' })),
    completion(talked({ reply: 'Has it happened before?' })),
  ]);
  const result = await createService({ client, finding: quiet }).talk(talkInput());
  assert.equal(result.reply, 'Has it happened before?');
  assert.equal(client.calls.length, 2);
});

test('Talk flags a legal question without needing a reply, and caps quick replies', async () => {
  const legal = await createService({ client: fakeClient([completion(talked({ reply: '', is_legal_question: true }))]), finding: quiet }).talk(talkInput('Will he go to jail?'));
  assert.equal(legal.is_legal_question, true);
  const chips = await createService({ client: fakeClient([completion(talked({ quick_replies: ['Yes', ' ', 'No', 'Maybe'] }))]), finding: quiet }).talk(talkInput());
  assert.deepEqual(chips.quick_replies, ['Yes', 'No']);
});

test('Talk accepts a null message at the start and rejects a missing one', async () => {
  const service = createService({ client: fakeClient([completion(talked())]), finding: quiet });
  assert.equal((await service.talk(talkInput(null))).reply, 'Has this happened before?');
  await assert.rejects(service.talk({ conversation: [], entries: [] }));
});
