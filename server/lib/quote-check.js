export function normalize(text) {
  return text.normalize('NFKC').toLowerCase().replace(/[“”]/gu, '"').replace(/[‘’]/gu, "'")
    .replace(/[^\p{L}\p{N}\s]/gu, '').replace(/\s+/gu, ' ').trim();
}

export function quoteFound(quote, text) {
  if (typeof quote !== 'string') return false;
  const needle = normalize(quote);
  return needle.length > 0 && normalize(text).includes(needle);
}
