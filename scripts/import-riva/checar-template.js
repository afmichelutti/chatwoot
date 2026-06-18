#!/usr/bin/env node
/*
 * checar-template.js — Inspeciona a definição de um template WhatsApp na conta
 * para confirmar se o header de imagem é obrigatório (e portanto se o media_url
 * vazio da campanha quebraria todos os envios). Somente-leitura.
 *
 * Uso: node checar-template.js [--template dia_dos_namorados_riva_001]
 */
const fs = require('fs');
const path = require('path');

function getArg(name, fb) { const i = process.argv.indexOf(`--${name}`); return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : fb; }
function loadEnv(p) {
  if (!fs.existsSync(p)) return {};
  const out = {};
  for (const line of fs.readFileSync(p, 'utf8').split(/\r?\n/)) {
    const t = line.trim(); if (!t || t.startsWith('#')) continue;
    const eq = t.indexOf('='); if (eq === -1) continue;
    let v = t.slice(eq + 1).trim();
    if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) v = v.slice(1, -1);
    out[t.slice(0, eq).trim()] = v;
  }
  return out;
}

const envFile = getArg('env', path.resolve(__dirname, '..', '..', 'docs', 'riva', '.env'));
const fe = loadEnv(envFile);
const URL = (getArg('url') || process.env.CHATWOOT_URL || fe.CHATWOOT_URL || '').replace(/\/+$/, '');
const ACCOUNT = getArg('account') || process.env.CHATWOOT_ACCOUNT_ID || fe.CHATWOOT_ACCOUNT_ID;
const TOKEN = getArg('token') || process.env.CHATWOOT_TOKEN || fe.CHATWOOT_TOKEN;
const TPL = getArg('template', 'dia_dos_namorados_riva_001');

if (!URL || !ACCOUNT || !TOKEN) { console.error('❌ Faltam credenciais.'); process.exit(1); }

async function api(p) {
  const res = await fetch(`${URL}/api/v1/accounts/${ACCOUNT}${p}`, { headers: { api_access_token: TOKEN } });
  const txt = await res.text();
  let j; try { j = txt ? JSON.parse(txt) : null; } catch { j = txt; }
  if (!res.ok) throw new Error(`HTTP ${res.status} em ${p}: ${typeof j === 'string' ? j : JSON.stringify(j)}`);
  return j;
}

(async () => {
  const inboxes = await api('/inboxes');
  const arr = Array.isArray(inboxes) ? inboxes : (inboxes?.payload || []);
  const wa = arr.filter((i) => (i.channel_type || '').includes('Whatsapp') || (i.channel_type || '').includes('whatsapp'));
  console.log(`📥 Inboxes WhatsApp encontradas: ${wa.length}`);

  let found = null, foundInbox = null;
  for (const i of arr) {
    const tpls = i.message_templates || i.channel?.message_templates || [];
    if (tpls.length) console.log(`  inbox [${i.id}] "${i.name}" — ${tpls.length} templates`);
    const m = tpls.find((t) => t.name === TPL);
    if (m) { found = m; foundInbox = i; }
  }

  if (!found) {
    console.log(`\n⚠️  Template "${TPL}" não veio na listagem de inboxes (a API pode não expor message_templates).`);
    console.log('Inboxes disponíveis:');
    arr.forEach((i) => console.log(`  • [${i.id}] ${i.name} (${i.channel_type})`));
    return;
  }

  console.log(`\n✅ Template "${TPL}" encontrado na inbox [${foundInbox.id}] ${foundInbox.name}`);
  console.log('  status   :', found.status);
  console.log('  category :', found.category);
  console.log('  language :', found.language);
  console.log('  components:');
  for (const comp of (found.components || [])) {
    let extra = '';
    if (comp.type === 'HEADER') extra = ` format=${comp.format}` + (comp.example ? ` example=${JSON.stringify(comp.example)}` : '');
    console.log(`    - ${comp.type}${extra}`);
    if (comp.type === 'HEADER' && comp.format && comp.format !== 'TEXT') {
      console.log(`      ⚠️  Header do tipo ${comp.format} é OBRIGATÓRIO. Sem media_url, a Meta rejeita TODO envio.`);
    }
  }
})().catch((e) => { console.error('💥', e.message); process.exit(1); });
