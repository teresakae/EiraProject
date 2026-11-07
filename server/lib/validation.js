export class AppError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

// These are the schema constructs used here, for request and response validation.
export function matches(value, schema) {
  const types = Array.isArray(schema.type) ? schema.type : [schema.type];
  const type = value === null ? 'null' : Array.isArray(value) ? 'array' : typeof value;
  if (!types.includes(type) && !(types.includes('integer') && Number.isInteger(value))) return false;
  if (schema.enum && !schema.enum.includes(value)) return false;
  if (type === 'object') {
    if (schema.required.some((key) => !Object.hasOwn(value, key))) return false;
    if (Object.keys(value).some((key) => !Object.hasOwn(schema.properties, key))) return false;
    return Object.entries(schema.properties).every(([key, child]) => matches(value[key], child));
  }
  if (type === 'array') return value.every((item) => matches(item, schema.items));
  return true;
}

export function requireInput(value, schema, job) {
  if (!matches(value, schema)
    || (job === 'extract' && !value.text.trim())
    || (job === 'ask' && !value.question.trim())) {
    throw new AppError(400, 'invalid_request', 'Ada bagian yang belum terbaca. Coba periksa isinya.');
  }
}
