import { createServer } from 'node:http';
import { Readable } from 'node:stream';
import { endpoint } from './lib/http.js';

const routes = new Map(['extract', 'ask', 'draft', 'transcribe'].map((job) => [`/api/${job}`, endpoint(job)]));
if (!process.env.EIRA_APP_TOKEN) {
  console.error('Set EIRA_APP_TOKEN in .env.local before starting.');
  process.exit(1);
}
const port = Number(process.env.PORT || 3000);
createServer(async (req, res) => {
  try {
    const url = new URL(req.url, 'http://localhost');
    const handler = routes.get(url.pathname);
    const request = new Request(url, {
      method: req.method, headers: req.headers,
      ...(req.method === 'GET' || req.method === 'HEAD' ? {} : { body: Readable.toWeb(req), duplex: 'half' }),
    });
    const response = handler ? await handler(request)
      : Response.json({ error: { code: 'not_found', message: 'Alamat ini belum tersedia.' } }, { status: 404, headers: { 'Cache-Control': 'no-store' } });
    res.writeHead(response.status, Object.fromEntries(response.headers));
    res.end(Buffer.from(await response.arrayBuffer()));
  } catch {
    res.writeHead(400, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
    res.end(JSON.stringify({ error: { code: 'invalid_request', message: 'Isinya belum terbaca.' } }));
  }
}).listen(port, '127.0.0.1', () => console.log(`Eira server: http://127.0.0.1:${port}`));
