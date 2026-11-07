import { cp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { parseFAQ } from '../lib/faq.js';

const root = new URL('../', import.meta.url);
const output = new URL('dist/', root);
await rm(output, { recursive: true, force: true });
await mkdir(new URL('data/', output), { recursive: true });
await mkdir(new URL('public/', output), { recursive: true });
// Explicit allowlist: never copy the repository or the docs directory.
for (const name of ['api', 'lib', 'prompts', 'config.js', 'package.json', 'package-lock.json']) {
  await cp(new URL(name, root), new URL(name, output), { recursive: true });
}
const source = await readFile(new URL('../../docs/FAQ_APPROVED.md', import.meta.url), 'utf8');
const approved = parseFAQ(source);
await writeFile(new URL('data/FAQ_APPROVED.md', output), approved.map(({ number, question, text }) =>
  `## ${number}. ${question}\n\nApproved text: ${text}\nSource: approved source file\nApproved by:\n`).join('\n'));
await writeFile(new URL('vercel.json', output), JSON.stringify({
  version: 2,
  buildCommand: 'mkdir -p public',
  outputDirectory: 'public',
  framework: null,
  functions: { 'api/*.js': { maxDuration: 120, includeFiles: '{prompts/**,data/FAQ_APPROVED.md}' } },
}, null, 2) + '\n');
console.log(`Built server/dist with ${approved.length} approved FAQ answers.`);
