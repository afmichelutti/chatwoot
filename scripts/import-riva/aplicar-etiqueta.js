#!/usr/bin/env node
/**
 * aplicar-etiqueta.js
 * -------------------------------------------------------------------------
 * Le o CSV limpo (gerado por limpar-contatos.js) e, para cada contato:
 *   1. Procura o contato no Chatwoot (por identifier riva_<num>, depois por telefone).
 *   2. Se nao existir, cria (name + phone_number + identifier).  [pode desligar com --no-create]
 *   3. Aplica a etiqueta do lote, fazendo UNIAO com as etiquetas que o
 *      contato ja tiver (o endpoint do Chatwoot substitui o conjunto, entao
 *      lemos as atuais antes para nao apagar nada).
 *
 * Assim a etiqueta cai em EXATAMENTE os contatos deste lote, sem selecao
 * manual. E idempotente: rodar de novo nao duplica nada.
 *
 * Credenciais (use variaveis de ambiente para nao deixar o token no historico):
 *   CHATWOOT_URL         ex.: https://app.seudominio.com   (sem barra no fim)
 *   CHATWOOT_ACCOUNT_ID  ex.: 1
 *   CHATWOOT_TOKEN       api_access_token do seu usuario (Perfil -> Token de Acesso)
 *
 * Ou passe por flag: --url, --account, --token.
 *
 * Uso:
 *   node aplicar-etiqueta.js --csv ../../docs/riva/contatos_dia_namorados.csv
 *
 * Opcoes:
 *   --csv <arquivo>      CSV limpo (padrao: docs/riva/contatos_dia_namorados.csv)
 *   --label <nome>       Etiqueta a aplicar (padrao: coluna "lista" do CSV)
 *   --url <url>          URL do Chatwoot      (ou env CHATWOOT_URL)
 *   --account <id>       Account ID           (ou env CHATWOOT_ACCOUNT_ID)
 *   --token <token>      api_access_token     (ou env CHATWOOT_TOKEN)
 *   --concurrency <n>    Requisicoes paralelas (padrao: 6)
 *   --no-create          Nao cria contatos faltantes, so etiqueta os existentes
 *   --dry-run            Nao altera nada; so mostra o que faria
 * -------------------------------------------------------------------------
 */

'use strict';

const fs = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------
function parseArgs(argv) {
  const out = {};
  for (let i = 2; i < argv.length; i += 1) {
    const a = argv[i];
    if (!a.startsWith('--')) continue;
    const key = a.slice(2);
    const next = argv[i + 1];
    if (next === undefined || next.startsWith('--')) {
      out[key] = true;
    } else {
      out[key] = next;
      i += 1;
    }
  }
  return out;
}

const args = parseArgs(process.argv);
const REPO_ROOT = path.resolve(__dirname, '..', '..');

const CSV_PATH = path.resolve(
  args.csv ? String(args.csv) : path.join(REPO_ROOT, 'docs', 'riva', 'contatos_dia_namorados.csv')
);
const URL = String(args.url || process.env.CHATWOOT_URL || '').replace(/\/+$/, '');
const ACCOUNT = String(args.account || process.env.CHATWOOT_ACCOUNT_ID || '');
const TOKEN = String(args.token || process.env.CHATWOOT_TOKEN || '');
const CONCURRENCY = args.concurrency ? Math.max(1, parseInt(args.concurrency, 10)) : 6;
const CREATE_MISSING = args['no-create'] !== true;
const DRY_RUN = args['dry-run'] === true;
const LABEL_OVERRIDE = args.label && args.label !== true ? String(args.label).trim() : null;

if (!URL || !ACCOUNT || !TOKEN) {
  console.error('Faltam credenciais. Defina CHATWOOT_URL, CHATWOOT_ACCOUNT_ID e CHATWOOT_TOKEN');
  console.error('(ou use --url --account --token).');
  process.exit(1);
}
if (!fs.existsSync(CSV_PATH)) {
  console.error(`CSV nao encontrado: ${CSV_PATH}`);
  process.exit(1);
}

const API = `${URL}/api/v1/accounts/${ACCOUNT}`;

// ---------------------------------------------------------------------------
// CSV parser (suficiente para o CSV que geramos: aspas + virgula + CRLF)
// ---------------------------------------------------------------------------
function parseCsv(text) {
  const rows = [];
  let field = '';
  let row = [];
  let inQuotes = false;
  for (let i = 0; i < text.length; i += 1) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') {
        if (text[i + 1] === '"') { field += '"'; i += 1; }
        else inQuotes = false;
      } else field += c;
    } else if (c === '"') {
      inQuotes = true;
    } else if (c === ',') {
      row.push(field); field = '';
    } else if (c === '\n') {
      row.push(field); field = '';
      if (row.length > 1 || row[0] !== '') rows.push(row);
      row = [];
    } else if (c !== '\r') {
      field += c;
    }
  }
  if (field !== '' || row.length) { row.push(field); rows.push(row); }
  return rows;
}

const raw = fs.readFileSync(CSV_PATH, 'utf8');
const rows = parseCsv(raw);
const header = rows.shift().map((h) => h.trim().toLowerCase());
const cName = header.indexOf('name');
const cPhone = header.indexOf('phone_number');
const cId = header.indexOf('identifier');
const cLista = header.indexOf('lista');

const records = rows
  .filter((r) => r.length && (r[cPhone] || '').trim())
  .map((r) => ({
    name: cName >= 0 ? (r[cName] || '').trim() : '',
    phone_number: (r[cPhone] || '').trim(),
    identifier: cId >= 0 ? (r[cId] || '').trim() : '',
    lista: cLista >= 0 ? (r[cLista] || '').trim() : '',
  }));

const LABEL = LABEL_OVERRIDE || (records[0] && records[0].lista) || 'dia_namorados';

// ---------------------------------------------------------------------------
// HTTP helpers
// ---------------------------------------------------------------------------
const HEADERS = { api_access_token: TOKEN, 'Content-Type': 'application/json' };
const sleep = (ms) => new Promise((res) => setTimeout(res, ms));

async function apiFetch(method, url, body, attempt = 1) {
  try {
    const resp = await fetch(url, {
      method,
      headers: HEADERS,
      body: body ? JSON.stringify(body) : undefined,
    });
    if (resp.status === 429 && attempt <= 5) {
      await sleep(attempt * 1000);
      return apiFetch(method, url, body, attempt + 1);
    }
    const text = await resp.text();
    let json = null;
    try { json = text ? JSON.parse(text) : null; } catch (_) { /* noop */ }
    return { status: resp.status, json, text };
  } catch (err) {
    if (attempt <= 5) {
      await sleep(attempt * 1000);
      return apiFetch(method, url, body, attempt + 1);
    }
    throw err;
  }
}

function pickContacts(json) {
  if (!json) return [];
  if (Array.isArray(json.payload)) return json.payload;
  if (json.payload && Array.isArray(json.payload.contacts)) return json.payload.contacts;
  return [];
}

async function findContact(rec) {
  // 1) por identifier (mais unico)
  if (rec.identifier) {
    const r = await apiFetch('GET', `${API}/contacts/search?q=${encodeURIComponent(rec.identifier)}`);
    const hit = pickContacts(r.json).find((c) => c.identifier === rec.identifier);
    if (hit) return hit;
  }
  // 2) por telefone
  const digits = rec.phone_number.replace(/\D/g, '');
  const r2 = await apiFetch('GET', `${API}/contacts/search?q=${encodeURIComponent(digits)}`);
  const hit2 = pickContacts(r2.json).find(
    (c) => (c.phone_number || '').replace(/\D/g, '') === digits
  );
  return hit2 || null;
}

async function createContact(rec) {
  const r = await apiFetch('POST', `${API}/contacts`, {
    name: rec.name || undefined,
    phone_number: rec.phone_number,
    identifier: rec.identifier || undefined,
  });
  const p = r.json && r.json.payload;
  const c = p && (p.contact || p);
  if (c && c.id) return c;
  throw new Error(`falha ao criar (${r.status}): ${(r.text || '').slice(0, 200)}`);
}

async function applyLabel(contactId) {
  // le labels atuais e faz uniao para nao apagar nada
  const cur = await apiFetch('GET', `${API}/contacts/${contactId}/labels`);
  const existing = (cur.json && Array.isArray(cur.json.payload)) ? cur.json.payload : [];
  if (existing.includes(LABEL)) return { changed: false };
  const labels = Array.from(new Set([...existing, LABEL]));
  const r = await apiFetch('POST', `${API}/contacts/${contactId}/labels`, { labels });
  if (r.status >= 200 && r.status < 300) return { changed: true };
  throw new Error(`falha ao etiquetar (${r.status}): ${(r.text || '').slice(0, 200)}`);
}

// ---------------------------------------------------------------------------
// Pool de concorrencia
// ---------------------------------------------------------------------------
const stats = { found: 0, created: 0, labeled: 0, alreadyLabeled: 0, errors: 0, processed: 0 };
const errorLog = [];

async function processRecord(rec) {
  try {
    let contact = await findContact(rec);
    if (contact) {
      stats.found += 1;
    } else if (CREATE_MISSING) {
      if (DRY_RUN) {
        stats.created += 1;
      } else {
        contact = await createContact(rec);
        stats.created += 1;
      }
    } else {
      errorLog.push(`${rec.phone_number}: nao encontrado (--no-create ativo)`);
      stats.errors += 1;
      return;
    }

    if (DRY_RUN) {
      stats.labeled += 1;
      return;
    }

    const id = contact ? contact.id : null;
    if (!id) { stats.errors += 1; return; }
    const res = await applyLabel(id);
    if (res.changed) stats.labeled += 1;
    else stats.alreadyLabeled += 1;
  } catch (err) {
    stats.errors += 1;
    errorLog.push(`${rec.phone_number}: ${err.message}`);
  } finally {
    stats.processed += 1;
    if (stats.processed % 50 === 0 || stats.processed === records.length) {
      process.stdout.write(`\r  Processados ${stats.processed}/${records.length} ...`);
    }
  }
}

async function runPool(items, worker, concurrency) {
  let idx = 0;
  const runners = Array.from({ length: Math.min(concurrency, items.length) }, async () => {
    while (idx < items.length) {
      const myIdx = idx;
      idx += 1;
      await worker(items[myIdx]);
    }
  });
  await Promise.all(runners);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
(async () => {
  console.log('');
  console.log('============ APLICAR ETIQUETA VIA API ============');
  console.log(`Chatwoot...........: ${API}`);
  console.log(`CSV................: ${CSV_PATH}`);
  console.log(`Contatos no CSV....: ${records.length}`);
  console.log(`Etiqueta...........: ${LABEL}`);
  console.log(`Criar faltantes....: ${CREATE_MISSING ? 'sim' : 'nao'}`);
  console.log(`Concorrencia.......: ${CONCURRENCY}`);
  console.log(`Modo...............: ${DRY_RUN ? 'DRY-RUN (nao altera nada)' : 'EXECUCAO REAL'}`);
  console.log('--------------------------------------------------');

  await runPool(records, processRecord, CONCURRENCY);

  console.log('\n--------------------------------------------------');
  console.log(`Encontrados........: ${stats.found}`);
  console.log(`Criados............: ${stats.created}`);
  console.log(`Etiquetados agora..: ${stats.labeled}`);
  console.log(`Ja tinham etiqueta.: ${stats.alreadyLabeled}`);
  console.log(`Erros..............: ${stats.errors}`);
  if (errorLog.length) {
    console.log('  Primeiros erros:');
    errorLog.slice(0, 15).forEach((e) => console.log(`    - ${e}`));
    const errFile = CSV_PATH.replace(/\.csv$/i, '') + '.erros.txt';
    fs.writeFileSync(errFile, errorLog.join('\n') + '\n', 'utf8');
    console.log(`  Log completo de erros: ${errFile}`);
  }
  console.log('==================================================');
})();
