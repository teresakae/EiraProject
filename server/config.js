export const models = {
  primary: process.env.OPENAI_TEXT_MODEL || 'gpt-6-luna',
  fallback: process.env.OPENAI_FALLBACK_MODEL || 'gpt-6.1-terra',
  transcribe: process.env.OPENAI_TRANSCRIBE_MODEL || 'gpt-transcribe',
};

export const limits = {
  jsonBytes: 1_000_000,
  audioBytes: 4_000_000,
  uploadBytes: 4_100_000,
  outputTokens: { extract: 4096, ask: 1536, talk: 1536, draft: 4096 },
};
