#!/usr/bin/env node
/**
 * testar-paginacao.js
 * Reproduz a paginacao da UI de Contatos para detectar duplicacao visual
 * causada por ORDER BY com empates (created_at/last_activity_at). NAO altera nada.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const REPO_ROOT = path.resolve(__dirname, '..', '..');
const ENV_PATH = path.join(REPO_ROOT, 'docs', 'riva', '.env');
function loadEnv(file) {
  const out = {};
  if (!fs.existsSync(file)) return out;
  for (const l of fs.readFileSync(file, 'utf8').split(/\r?\n/)) {
    const s = l.trim(); if (!s || s.startsWith('#')) continue;
    const i = s.indexOf('='); if (i === -1) continue;
    let v = s.slice(i + 1).trim();
    if ((v[0] === '"' && v.endsWith('"')) || (v[0] === "'" && v.endsWith("'"))) v = v.slice(1, -1);
    out[s.slice(0, i).trim()] = v;
  }
  return out;
}
const env = loadEnv(ENV_PATH);
const URL = String(env.CHATWOOT_URL || '').replace(/\/+$/, '');
const ACCOUNT = String(env.CHATWOOT_ACCOUNT_ID || '');
const TOKEN = String(env.CHATWOOT_TOKEN || '');
const API = `${URL}/api/v1/accounts/${ACCOUNT}`;
const HEADERS = { api_access_token: TOKEN, 'Content-Type': 'application/json' };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function get(url, attempt = 1) {
  try {
    const r = await fetch(url, { headers: HEADERS });
    if (r.status === 429 && attempt <= 6) { await sleep(attempt * 1000); return get(url, attempt + 1); }
    const t = await r.text(); let j = null; try { j = JSON.parse(t); } catch (_) {}
    return { status: r.status, json: j, text: t };
  } catch (e) { if (attempt <= 6) { await sleep(attempt * 1000); return get(url, attempt + 1); } throw e; }
}

async function sweep(label, sortParam) {
  const seenIds = new Map(); // id -> [pages]
  let page = 1, n = 1, totalRows = 0;
  while (n > 0 && page <= 200) {
    const q = sortParam ? `&sort=${encodeURIComponent(sortParam)}` : '';
    const r = await get(`${API}/contacts?page=${page}${q}`);
    if (r.status !== 200) { console.log(`  page ${page} -> HTTP ${r.status}`); break; }
    const p = (r.json && r.json.payload) || [];
    n = p.length;
    for (const c of p) {
      totalRows += 1;
      if (!seenIds.has(c.id)) seenIds.set(c.id, []);
      seenIds.get(c.id).push(page);
    }
    page += 1;
  }
  const repeated = [...seenIds.entries()].filter(([, pages]) => pages.length > 1);
  console.log(`\n[sort=${label}]`);
  console.log(`  Filas recebidas (todas paginas).: ${totalRows}`);
  console.log(`  Contatos DISTINTOS (id unico)...: ${seenIds.size}`);
  console.log(`  Contatos que apareceram >1 vez..: ${repeated.length}`);
  for (const [id, pages] of repeated.slice(0, 10)) console.log(`    id ${id} -> paginas [${pages.join(', ')}]`);
  if (repeated.length > 10) console.log(`    ... e mais ${repeated.length - 10}`);
  return { totalRows, distinct: seenIds.size, repeated: repeated.length };
}

(async () => {
  console.log(`Conta: ${API}  (token ...${TOKEN.slice(-4)})`);
  // ordens candidatas que a UI pode usar
  for (const [label, param] of [
    ['(default sem sort)', ''],
    ['last_activity_at_desc', '-last_activity_at'],
    ['last_activity_at_asc', 'last_activity_at'],
    ['name', 'name'],
    ['-created_at', '-created_at'],
  ]) {
    await sweep(label, param);
  }
})();
