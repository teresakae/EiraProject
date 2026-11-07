import { readFile } from 'node:fs/promises';

// Invented samples are read from the team's fixture file, never the legal files.
const markdown = await readFile(new URL('../../docs/FIXTURES.md', import.meta.url), 'utf8');
export const M1 = markdown.match(/^> (Semalam sekitar jam 11[^\n]+)/mu)[1];
export const T3 = [...markdown.matchAll(/^\| [1-5] \| ([^|]+) \|/gmu)].map((match) => match[1].trim());
const addition = (id) => markdown.match(new RegExp(`^\\| ${id} \\| ([^|]+) \\|`, 'mu'))[1].trim();
export const X1 = addition('X1');
export const X3 = addition('X3');
export const X4 = addition('X4');
export const X5 = addition('X5');

// All wording in this test FAQ is invented solely for the tests.
export function testFAQ(numbers = [3, 4]) {
  const invented = {
    3: 'Teks rekaan untuk pengujian, bukan informasi hukum. Cerita tentang ditampar bisa menunjukkan kemungkinan kekerasan fisik. Dalam contoh fiktif ini, Pasal 6 menjelaskan bentuk fisik. Ini bukan putusan bahwa seseorang melakukan kejahatan. Polisi dan pengadilan yang menilai kejadian.',
    4: 'Teks rekaan untuk pengujian, bukan informasi hukum. Dalam aturan fiktif untuk tes ini, rentang hukuman umum adalah satu sampai dua tahun. Itu informasi umum, bukan hukuman untuk suaminya. Hakim yang menentukan setiap kasus. Teks uji ini tidak menjawab siapa yang membiayai anak.',
    7: 'Teks rekaan untuk pengujian. Jawaban tentang perlindungan belum dapat dipastikan dan bisa ditanyakan kepada layanan manusia.',
    11: 'Teks rekaan untuk pengujian. Jawaban tentang menarik keputusan belum dapat dipastikan dan bisa ditanyakan kepada layanan manusia.',
  };
  return numbers.map((number) => `## ${number}. Pertanyaan uji ${number}\n\nApproved text: ${invented[number]}\nSource: invented test setup\nApproved by: invented test setup\n`).join('\n');
}
