export const object = (properties) => ({
  type: 'object', properties, required: Object.keys(properties), additionalProperties: false,
});
const text = { type: 'string' };
const nullableText = { type: ['string', 'null'] };
const texts = { type: 'array', items: text };

export const eventSchema = object({
  when_text: nullableText,
  what_happened: text,
  injuries: nullableText,
  witnesses: texts,
  quote: text,
  pkdrt_type: { type: 'string', enum: ['fisik', 'psikis', 'seksual', 'penelantaran', 'tidak_yakin'] },
});
export const extractSchema = object({ events: { type: 'array', items: eventSchema }, cover_task: text, reply: text });
export const askSchema = object({
  answer: text,
  faq_answers_used: { type: 'array', items: { type: 'integer' } },
  articles_named: texts,
  not_sure: { type: 'boolean' },
});

export const talkSchema = object({
  reply: text,
  is_legal_question: { type: 'boolean' },
  quick_replies: texts,
  facts: { type: 'array', items: object({
    category: { type: 'string', enum: ['who', 'what', 'when', 'where'] },
    value: text,
    quote: text,
  }) },
});

export const dropdowns = {
  is_victim: ['saya_sendiri', 'orang_lain'],
  level_concern: ['sedikit_khawatir', 'khawatir', 'sangat_khawatir'],
  relationship_with_victim: ['Orang Tidak Dikenal', 'Diri Sendiri', 'Kenalan Baru', 'Pengurus Rumah Tangga', 'Guru', 'Lainnya', 'Petugas Layanan', 'Petugas Sekolah', 'Teman', 'Suami/Istri', 'Tetangga/ Teman keluarga', 'Kerabat', 'Ayah Kandung', 'Ibu Kandung', 'Pengasuh Utama', 'Anak', 'Pacar', 'Rekan Kerja', 'Atasan / Majikan'],
  incident_time: ['Pagi', 'Siang', 'Sore', 'Malam', 'Tidak Diketahui'],
  location: ['Rumah Tangga', 'Tempat Kerja', 'Sekolah/Kampus', 'Sarana Umum', 'Situasi Darurat/Tempat Bencana', 'Daring/Elektronik'],
  korban_gender: ['laki-laki', 'perempuan'],
  korban_disabilities_type: [
    'Mengalami kesulitan melihat, meskipun memakai kacamata',
    'Mengalami kesulitan mendengar, meskipun menggunakan alat bantu dengar',
    'Mengalami kesulitan berkomunikasi, misalnya memahami atau dimengerti',
    'Mengalami kesulitan mengingat atau berkonsentrasi',
    'Mengalami kesulitan dengan perawatan diri seperti membersihkan seluruh tubuh atau berpakaian',
    'Mengalami kesulitan berjalan atau menaiki tangga',
  ],
};
const booleanFields = new Set(['korban_disabilities', 'anonymous']);
export const fieldNames = ['is_victim', 'level_concern', 'relationship_with_victim', 'incident_time', 'location', 'province_city', 'description', 'korban_fullname', 'korban_gender', 'korban_age', 'korban_disabilities', 'korban_disabilities_type', 'korban_contact_number', 'korban_trusted_person', 'reporter_fullname', 'anonymous', 'contact_number'];
export const draftSchema = object(Object.fromEntries(fieldNames.map((field) => {
  const value = dropdowns[field]
    ? { type: ['string', 'null'], enum: [...dropdowns[field], null] }
    : { type: [field === 'korban_age' ? 'integer' : booleanFields.has(field) ? 'boolean' : 'string', 'null'] };
  return [field, object({ value, quote: nullableText })];
})));

export const requestSchemas = {
  extract: object({ text }),
  ask: object({
    question: text,
    conversation: { type: 'array', items: object({ role: { type: 'string', enum: ['user', 'assistant'] }, text }) },
    entries: { type: 'array', items: object({ text, events: { type: 'array', items: eventSchema } }) },
  }),
  talk: object({
    message: nullableText,
    conversation: { type: 'array', items: object({ role: { type: 'string', enum: ['user', 'assistant'] }, text }) },
    entries: { type: 'array', items: object({ text, events: { type: 'array', items: eventSchema } }) },
  }),
  draft: object({ entries: texts, questions: texts }),
};
