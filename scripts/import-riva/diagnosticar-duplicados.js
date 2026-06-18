#!/usr/bin/env node
/**
 * diagnosticar-duplicados.js
 * -------------------------------------------------------------------------
 * Conecta na conta do Chatwoot (le credenciais de docs/riva/.env) e descobre
 * de onde vem os numeros repetidos que o cliente esta reclamando.
 *
 * NAO altera nada. So le e relata. Investiga:
 *   1. Duplicados DENTRO do CSV (mesmo numero em linhas diferentes).
 *   2. Duplicados NA CONTA por phone_number normalizado (digitos).
 *   3. Duplicados NA CONTA por identifier riva_*.
 *   4. Contatos do CSV que existem >1 vez na conta (numero repetido de fato).
 *   5. Variantes de mesmo numero (com/sem 9o digito, com/sem +55) que
 *      escaparam da deduplicacao.
 *
 * Uso:
 *   node diagnosticar-duplicados.js [--csv <arquivo>] [--label dia_namorados]
 * -------------------------------------------------------------------------
 */
'use strict';

const fs = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// Carrega docs/riva/.env manualmente (sem dependencia externa)
// ---------------------------------------------------------------------------
const REPO_ROOT = path.resolve(__dirname, '..', '..');
const ENV_PATH = path.join(REPO_ROOT, 'docs', 'riva', '.env');

function loadEnv(file) {
  if (!fs.existsSync(file)) return {};
  const out = {};
  for (const lineRaw of fs.readFileSync(file, 'utf8').split(/\r?\n/)) {
    const line = lineRaw.trim();
    if (!line || line.startsWith('#')) continue;
    const eq = line.indexOf('=');
    if (eq === -1) continue;
    const k = line.slice(0, eq).trim();
    let v = line.slice(eq + 1).trim();
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
      v = v.slice(1, -1);
    }
    out[k] = v;
  }
  return out;
}

const env = loadEnv(ENV_PATH);
const URL = String(env.CHATWOOT_URL || process.env.CHATWOOT_URL || '').replace(/\/+$/, '');
const ACCOUNT = String(env.CHATWOOT_ACCOUNT_ID || process.env.CHATWOOT_ACCOUNT_ID || '');
const TOKEN = String(env.CHATWOOT_TOKEN || process.env.CHATWOOT_TOKEN || '');

function parseArgs(argv) {
  const out = {};
  for (let i = 2; i < argv.length; i += 1) {
    const a = argv[i];
    if (!a.startsWith('--')) continue;
    const key = a.slice(2);
    const next = argv[i + 1];
    if (next === undefined || next.startsWith('--')) out[key] = true;
    else { out[key] = next; i += 1; }
  }
  return out;
}
const args = parseArgs(process.argv);
const CSV_PATH = path.resolve(
  args.csv ? String(args.csv) : path.join(REPO_ROOT, 'docs', 'riva', 'contatos_dia_namorados.csv')
);
const LABEL = args.label && args.label !== true ? String(args.label).trim() : 'dia_namorados';

if (!URL || !ACCOUNT || !TOKEN) {
  console.error('Faltam credenciais no .env:', ENV_PATH);
  console.error(`  URL=${URL ? 'ok' : 'FALTA'} ACCOUNT=${ACCOUNT ? 'ok' : 'FALTA'} TOKEN=${TOKEN ? 'ok' : 'FALTA'}`);
  process.exit(1);
}
console.log(`Conta: ${URL}/api/v1/accounts/${ACCOUNT}  (token ...${TOKEN.slice(-4)})`);

const API = `${URL}/api/v1/accounts/${ACCOUNT}`;
const HEADERS = { api_access_token: TOKEN, 'Content-Type': 'application/json' };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const digitsOf = (v) => String(v == null ? '' : v).replace(/\D/g, '');

async function apiFetch(method, url, body, attempt = 1) {
  try {
    const resp = await fetch(url, {
      method,
      headers: HEADERS,
      body: body ? JSON.stringify(body) : undefined,
    });
    if (resp.status === 429 && attempt <= 6) { await sleep(attempt * 1000); return apiFetch(method, url, body, attempt + 1); }
    const text = await resp.text();
    let json = null;
    try { json = text ? JSON.parse(text) : null; } catch (_) {}
    return { status: resp.status, json, text };
  } catch (err) {
    if (attempt <= 6) { await sleep(attempt * 1000); return apiFetch(method, url, body, attempt + 1); }
    throw err;
  }
}

// ---------------------------------------------------------------------------
// 1) Lê o CSV e procura duplicados internos
// ---------------------------------------------------------------------------
function parseCsv(text) {
  const rows = [];
  let field = '', row = [], q = false;
  for (let i = 0; i < text.length; i += 1) {
    const c = text[i];
    if (q) {
      if (c === '"') { if (text[i + 1] === '"') { field += '"'; i += 1; } else q = false; }
      else field += c;
    } else if (c === '"') q = true;
    else if (c === ',') { row.push(field); field = ''; }
    else if (c === '\n') { row.push(field); field = ''; if (row.length > 1 || row[0] !== '') rows.push(row); row = []; }
    else if (c !== '\r') field += c;
  }
  if (field !== '' || row.length) { row.push(field); rows.push(row); }
  return rows;
}

function analyzeCsv() {
  if (!fs.existsSync(CSV_PATH)) { console.log(`\n[CSV] nao encontrado: ${CSV_PATH} (pulando analise do CSV)`); return null; }
  const rows = parseCsv(fs.readFileSync(CSV_PATH, 'utf8'));
  const header = rows.shift().map((h) => h.trim().toLowerCase());
  const cPhone = header.indexOf('phone_number');
  const cId = header.indexOf('identifier');
  const byPhone = new Map();
  let total = 0;
  for (const r of rows) {
    const phone = (r[cPhone] || '').trim();
    if (!phone) continue;
    total += 1;
    const d = digitsOf(phone);
    if (!byPhone.has(d)) byPhone.set(d, []);
    byPhone.get(d).push({ phone, identifier: cId >= 0 ? (r[cId] || '').trim() : '' });
  }
  const dups = [...byPhone.entries()].filter(([, v]) => v.length > 1);
  console.log('\n================ CSV ================');
  console.log(`Arquivo...........: ${CSV_PATH}`);
  console.log(`Linhas com telefone: ${total}`);
  console.log(`Numeros distintos.: ${byPhone.size}`);
  console.log(`Numeros repetidos no CSV: ${dups.length}`);
  for (const [d, v] of dups.slice(0, 20)) console.log(`  +${d} -> ${v.length}x`);
  if (dups.length > 20) console.log(`  ... e mais ${dups.length - 20}`);
  return { byPhone, total };
}

// ---------------------------------------------------------------------------
// 2) Puxa TODOS os contatos da conta (paginado)
// ---------------------------------------------------------------------------
async function fetchAllContacts() {
  const all = [];
  let page = 1;
  // tenta descobrir o total
  const first = await apiFetch('GET', `${API}/contacts?page=1&sort=-created_at`);
  const count = first.json && first.json.meta ? (first.json.meta.count ?? first.json.meta.total_count) : null;
  if (first.status !== 200) {
    console.error(`Erro ao listar contatos (${first.status}): ${(first.text || '').slice(0, 300)}`);
    process.exit(1);
  }
  const pushPayload = (j) => { const p = (j && j.payload) || []; for (const c of p) all.push(c); return p.length; };
  let n = pushPayload(first.json);
  process.stdout.write(`\r[API] contatos baixados: ${all.length}`);
  while (n > 0) {
    page += 1;
    const r = await apiFetch('GET', `${API}/contacts?page=${page}&sort=-created_at`);
    if (r.status !== 200) break;
    n = pushPayload(r.json);
    process.stdout.write(`\r[API] contatos baixados: ${all.length}`);
  }
  console.log('');
  return { all, reportedCount: count };
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
(async () => {
  const csv = analyzeCsv();

  console.log('\n================ CONTA (API) ================');
  const { all, reportedCount } = await fetchAllContacts();
  console.log(`Total de contatos baixados: ${all.length}` + (reportedCount != null ? ` (meta.count=${reportedCount})` : ''));

  // Duplicados por phone_number (digitos)
  const byPhone = new Map();
  const noPhone = [];
  for (const c of all) {
    const d = digitsOf(c.phone_number);
    if (!d) { noPhone.push(c); continue; }
    if (!byPhone.has(d)) byPhone.set(d, []);
    byPhone.get(d).push(c);
  }
  const phoneDups = [...byPhone.entries()].filter(([, v]) => v.length > 1).sort((a, b) => b[1].length - a[1].length);

  console.log(`\n-- Duplicados por phone_number (digitos identicos) --`);
  console.log(`Numeros com >1 contato: ${phoneDups.length}`);
  let extra = 0;
  for (const [, v] of phoneDups) extra += v.length - 1;
  console.log(`Contatos "extras" (repetidos): ${extra}`);
  for (const [d, v] of phoneDups.slice(0, 30)) {
    console.log(`  +${d} -> ${v.length}x  ids=[${v.map((c) => c.id).join(', ')}]  ident=[${v.map((c) => c.identifier || '-').join(', ')}]`);
  }
  if (phoneDups.length > 30) console.log(`  ... e mais ${phoneDups.length - 30} numeros repetidos`);

  // Duplicados por identifier
  const byId = new Map();
  for (const c of all) {
    const id = (c.identifier || '').trim();
    if (!id) continue;
    if (!byId.has(id)) byId.set(id, []);
    byId.get(id).push(c);
  }
  const idDups = [...byId.entries()].filter(([, v]) => v.length > 1);
  console.log(`\n-- Duplicados por identifier --`);
  console.log(`Identifiers com >1 contato: ${idDups.length}`);
  for (const [id, v] of idDups.slice(0, 20)) console.log(`  ${id} -> ${v.length}x ids=[${v.map((c) => c.id).join(', ')}]`);

  // Variantes do mesmo numero (com/sem 9o digito) que NAO casam por digitos
  // Agrupa por (DDD + ultimos 8 digitos) para pegar o par 10dig vs 11dig.
  const byTail = new Map();
  for (const c of all) {
    let d = digitsOf(c.phone_number);
    if (d.startsWith('55')) d = d.slice(2);
    if (d.length < 10) continue;
    const ddd = d.slice(0, 2);
    const last8 = d.slice(-8);
    const key = ddd + last8;
    if (!byTail.has(key)) byTail.set(key, new Set());
    byTail.get(key).add(digitsOf(c.phone_number));
  }
  const variantDups = [...byTail.entries()].filter(([, set]) => set.size > 1);
  console.log(`\n-- Variantes do mesmo numero (com/sem 9o digito, com/sem 55) --`);
  console.log(`Numeros com variantes que escaparam da dedup: ${variantDups.length}`);
  for (const [key, set] of variantDups.slice(0, 20)) console.log(`  DDD+8=${key} -> variantes: ${[...set].map((x) => '+' + x).join(' , ')}`);

  // CSV x conta: numeros do CSV que aparecem >1 vez na conta
  if (csv) {
    let csvWithDupInAccount = 0;
    for (const [d] of csv.byPhone) {
      const found = byPhone.get(d);
      if (found && found.length > 1) csvWithDupInAccount += 1;
    }
    console.log(`\n-- CSV x Conta --`);
    console.log(`Numeros do CSV que estao duplicados na conta: ${csvWithDupInAccount}`);
  }

  // Quantos sao do lote riva_ vs pre-existentes
  let rivaCount = 0, semIdent = 0, outroIdent = 0;
  for (const c of all) {
    const id = (c.identifier || '').trim();
    if (!id) semIdent += 1;
    else if (id.startsWith('riva_')) rivaCount += 1;
    else outroIdent += 1;
  }
  console.log(`\n-- Origem dos contatos --`);
  console.log(`Com identifier riva_*...: ${rivaCount}`);
  console.log(`Com outro identifier....: ${outroIdent}`);
  console.log(`Sem identifier..........: ${semIdent}`);

  // Nomes repetidos (o que o cliente pode estar vendo como "repetido")
  const byName = new Map();
  for (const c of all) {
    const nm = (c.name || '').trim().toLowerCase();
    if (!nm) continue;
    if (!byName.has(nm)) byName.set(nm, []);
    byName.get(nm).push(c);
  }
  const nameDups = [...byName.entries()].filter(([, v]) => v.length > 1).sort((a, b) => b[1].length - a[1].length);
  let nameExtra = 0;
  for (const [, v] of nameDups) nameExtra += v.length - 1;
  console.log(`\n-- Nomes repetidos (mesmo nome, telefones diferentes) --`);
  console.log(`Nomes com >1 contato....: ${nameDups.length}  (=> ${nameExtra} contatos com nome repetido)`);
  for (const [nm, v] of nameDups.slice(0, 25)) {
    console.log(`  "${nm}" -> ${v.length}x  fones=[${v.map((c) => c.phone_number || '-').join(' , ')}]`);
  }
  if (nameDups.length > 25) console.log(`  ... e mais ${nameDups.length - 25} nomes repetidos`);

  console.log('\n================ RESUMO ================');
  console.log(`Contatos na conta.........: ${all.length}`);
  console.log(`Sem phone_number..........: ${noPhone.length}`);
  console.log(`Numeros repetidos (phone).: ${phoneDups.length}  (=> ${extra} contatos extras a remover)`);
  console.log(`Identifiers repetidos.....: ${idDups.length}`);
  console.log(`Variantes 9digito/55......: ${variantDups.length}`);
  console.log('\nNada foi alterado. Diagnostico apenas.');
})();
