import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { readFileSync, existsSync, statSync } from 'node:fs';
import { join, extname } from 'node:path';

const webDir = process.argv[2];
if (!webDir || !existsSync(webDir)) {
  console.error(`Usage: node browser_smoke.mjs <path-to-build-web-dir>`);
  process.exit(1);
}

const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.wasm': 'application/wasm',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
};

// Start simple HTTP static server with correct MIME types (especially for .wasm)
const server = createServer((req, res) => {
  let reqPath = req.url.split('?')[0];
  if (reqPath === '/') reqPath = '/index.html';
  const filePath = join(webDir, reqPath);

  if (existsSync(filePath) && statSync(filePath).isFile()) {
    const ext = extname(filePath);
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    res.writeHead(200, {
      'Content-Type': contentType,
      'Cross-Origin-Embedder-Policy': 'require-corp',
      'Cross-Origin-Opener-Policy': 'same-origin',
    });
    res.end(readFileSync(filePath));
  } else {
    res.writeHead(404);
    res.end('Not found');
  }
});

await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
const port = server.address().port;
console.log(`Serving ${webDir} on http://127.0.0.1:${port}`);

const cdpPort = 9222 + Math.floor(Math.random() * 1000);
const chrome = spawn(
  process.env.CHROME_EXECUTABLE || '/usr/sbin/chromium',
  [
    '--headless=new',
    '--no-sandbox',
    '--disable-gpu',
    `--remote-debugging-port=${cdpPort}`,
    `http://127.0.0.1:${port}`,
  ],
  { stdio: ['ignore', 'ignore', 'pipe'] }
);

chrome.stderr.on('data', (d) => {
  // console.error('[Chrome STDERR]', d.toString());
});

let chromeExited = false;
chrome.on('exit', (code) => {
  chromeExited = true;
});

// Wait for CDP to be ready
let wsUrl = null;
for (let i = 0; i < 30; i++) {
  await new Promise((r) => setTimeout(r, 200));
  try {
    const resp = await fetch(`http://127.0.0.1:${cdpPort}/json`);
    const targets = await resp.json();
    const page = targets.find((t) => t.type === 'page' && t.webSocketDebuggerUrl);
    if (page) {
      wsUrl = page.webSocketDebuggerUrl;
      break;
    }
  } catch (e) {}
}

if (!wsUrl) {
  console.error('Failed to connect to Chromium CDP endpoint.');
  chrome.kill('SIGKILL');
  server.close();
  process.exit(1);
}

const ws = new WebSocket(wsUrl);
await new Promise((resolve, reject) => {
  ws.onopen = resolve;
  ws.onerror = reject;
});

ws.send(JSON.stringify({ id: 1, method: 'Runtime.enable' }));
ws.send(JSON.stringify({ id: 2, method: 'Log.enable' }));

const results = {};
let completed = false;

ws.onmessage = (event) => {
  try {
    const msg = JSON.parse(event.data);
    if (msg.method === 'Runtime.consoleAPICalled') {
      const text = msg.params.args.map((a) => a.value ?? a.description ?? '').join(' ');
      console.log('[BROWSER CONSOLE]', text);
      if (text.includes('[RESULT]')) {
        if (text.includes('emscripten/native_example.js')) {
          results['emscripten'] = text;
        }
        if (text.includes('standalone/native_example.wasm')) {
          results['standalone'] = text;
        }
      }
    }
    if (msg.method === 'Log.entryAdded') {
      console.log('[BROWSER LOG]', msg.params.entry.text);
    }
  } catch (e) {}
};

const startTime = Date.now();
while (Date.now() - startTime < 30000) {
  if (results['emscripten'] && results['standalone']) {
    completed = true;
    break;
  }
  await new Promise((r) => setTimeout(r, 250));
}

ws.close();
chrome.kill('SIGKILL');
server.close();

console.log('--- Smoke Test Verification ---');
console.log('Emscripten result:', results['emscripten']);
console.log('Standalone result:', results['standalone']);

if (!completed) {
  console.error('FAIL: Timeout waiting for both module results in browser.');
  process.exit(1);
}

if (
  !results['emscripten'].includes('Library Name: native_example') ||
  !results['emscripten'].includes('Static Init Check: true') ||
  !results['standalone'].includes('Library Name: native_example') ||
  !results['standalone'].includes('Static Init Check: true')
) {
  console.error('FAIL: Output values did not match expected values.');
  process.exit(1);
}

console.log('PASS: Both Emscripten JS and Standalone WASM invoked successfully!');
process.exit(0);
