import { timingSafeEqual } from 'node:crypto';
import { limits } from '../config.js';
import { createService } from './service.js';
import { AppError } from './validation.js';

const headers = { 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' };
const service = createService();

async function readLimited(request, limit) {
  if (Number(request.headers.get('content-length')) > limit) throw new AppError(413, 'request_too_large', 'Isinya melebihi batas ukuran.');
  const reader = request.body?.getReader();
  if (!reader) throw new AppError(400, 'invalid_request', 'Isinya belum terbaca.');
  let size = 0;
  const chunks = [];
  try {
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > limit) {
        await reader.cancel();
        throw new AppError(413, 'request_too_large', 'Isinya melebihi batas ukuran.');
      }
      chunks.push(value);
    }
    return Buffer.concat(chunks, size);
  } finally {
    reader.releaseLock();
  }
}

export function endpoint(job, { app = service, token = () => process.env.EIRA_APP_TOKEN } = {}) {
  return async (request) => {
    try {
      if (request.method !== 'POST') {
        return Response.json({ error: { code: 'method_not_allowed', message: 'Cara akses ini belum didukung.' } }, { status: 405, headers: { ...headers, Allow: 'POST' } });
      }
      const secret = token();
      if (!secret) throw new AppError(503, 'server_not_configured', 'Aku belum bisa memprosesnya sekarang.');
      const actual = Buffer.from(request.headers.get('authorization') || '');
      const expected = Buffer.from(`Bearer ${secret}`);
      if (actual.length !== expected.length || !timingSafeEqual(actual, expected)) {
        throw new AppError(401, 'unauthorized', 'Akses belum tersedia.');
      }
      let input;
      const type = request.headers.get('content-type') || '';
      if (job === 'transcribe') {
        if (!/^multipart\/form-data\s*;/iu.test(type)) throw new AppError(415, 'unsupported_media_type', 'Format rekamannya belum bisa dibaca.');
        const bytes = await readLimited(request, limits.uploadBytes);
        let form;
        try {
          form = await new Request('http://localhost', { method: 'POST', headers: { 'content-type': type }, body: bytes }).formData();
        } catch {
          throw new AppError(400, 'invalid_request', 'Rekamannya belum terbaca.');
        }
        if ([...form.keys()].some((key) => !['file', 'language'].includes(key))
          || form.getAll('file').length !== 1 || form.getAll('language').length > 1
          || (form.has('language') && form.get('language') !== 'id')) {
          throw new AppError(400, 'invalid_request', 'Rekamannya belum terbaca.');
        }
        input = form.get('file');
      } else {
        if (!/^application\/json(?:\s*;|$)/iu.test(type)) throw new AppError(415, 'unsupported_media_type', 'Format isinya belum terbaca.');
        const bytes = await readLimited(request, limits.jsonBytes);
        try { input = JSON.parse(bytes.toString('utf8')); } catch {
          throw new AppError(400, 'invalid_request', 'Isinya belum terbaca.');
        }
      }
      return Response.json(await app[job](input), { headers });
    } catch (error) {
      const known = error instanceof AppError;
      return Response.json({ error: {
        code: known ? error.code : 'service_unavailable',
        message: known ? error.message : 'Aku belum bisa memprosesnya. Kamu bisa coba lagi nanti.',
      } }, { status: known ? error.status : 502, headers });
    }
  };
}
