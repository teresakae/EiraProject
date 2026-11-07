import { readFile } from 'node:fs/promises';

export function parseFAQ(markdown) {
  const answers = [];
  const numbers = new Set();
  const sections = markdown.split(/^## (?=\d+\.)/mu).slice(1);
  for (const section of sections) {
    const heading = section.match(/^(\d+)\.\s+([^\n]+)\r?\n/u);
    const approved = section.match(/^Approved text:\s*([\s\S]*?)^Source:/mu);
    if (!heading || !approved) continue;
    const text = approved[1].trim();
    if (!text || /TO FILL IN/iu.test(text)) continue;
    const number = Number(heading[1]);
    if (numbers.has(number)) throw new Error('Duplicate approved FAQ number');
    numbers.add(number);
    answers.push({ number, question: heading[2].trim(), text });
  }
  return answers;
}

export async function loadFAQ() {
  // The build copies only this approved file into server/data for deployment.
  try {
    return parseFAQ(await readFile(new URL('../data/FAQ_APPROVED.md', import.meta.url), 'utf8'));
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
    return parseFAQ(await readFile(new URL('../../docs/FAQ_APPROVED.md', import.meta.url), 'utf8'));
  }
}
