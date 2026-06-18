#!/usr/bin/env node
/*
 * ler-campanha.js — Lê uma campanha do Chatwoot e diagnostica se foi enviada.
 *
 * Contexto importante (app/services/whatsapp/oneoff_campaign_service.rb):
 *   O serviço marca a campanha como `completed!` ANTES de processar o envio.
 *   Portanto, status "concluída/completed" NÃO prova que as mensagens saíram.
 *   Falhas de envio são engolidas (rescue) e a audiência pode estar vazia ou
 *   sem template_params, resultando em "concluída" sem nenhum envio.
 *
 * Este script é somente-leitura: não altera nada no Chatwoot.
 *
 * Uso:
 *   node ler-campanha.js                         # busca "Mês dos namorados"
 *   node ler-campanha.js --title "Mês dos namorados"
 *   node ler-campanha.js --env ../../docs/riva/.env
 *
 * Credenciais (do .env ou flags):
 *   CHATWOOT_URL, CHATWOOT_ACCOUNT_ID, CHATWOOT_TOKEN
 *   ou --url, --account, --token
 */

const fs = require('fs');
const path = require('path');

// ---------- CLI args ----------
function getArg(name, fallback = undefined) {
  const i = process.argv.indexOf(`--${name}`);
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
}

// ---------- .env loader (sem dependências) ----------
function loadEnv(envPath) {
  if (!fs.existsSync(envPath)) return {};
  const out = {};
  const raw = fs.readFileSync(envPath, 'utf8');
  for (const line of raw.split(/\r?\n/)) {
    const t = line.trim();
    if (!t || t.startsWith('#')) continue;
    const eq = t.indexOf('=');
    if (eq === -1) continue;
    const key = t.slice(0, eq).trim();
    let val = t.slice(eq + 1).trim();
    if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
      val = val.slice(1, -1);
    }
    out[key] = val;
  }
  return out;
}

const DEFAULT_ENV = path.resolve(__dirname, '..', '..', 'docs', 'riva', '.env');
const envFile = getArg('env', DEFAULT_ENV);
const fileEnv = loadEnv(envFile);

const URL = (getArg('url') || process.env.CHATWOOT_URL || fileEnv.CHATWOOT_URL || '').replace(/\/+$/, '');
const ACCOUNT = getArg('account') || process.env.CHATWOOT_ACCOUNT_ID || fileEnv.CHATWOOT_ACCOUNT_ID;
const TOKEN = getArg('token') || process.env.CHATWOOT_TOKEN || fileEnv.CHATWOOT_TOKEN;
const TITLE = getArg('title', 'Mês dos namorados');

if (!URL || !ACCOUNT || !TOKEN) {
  console.error('❌ Faltam credenciais. Defina CHATWOOT_URL, CHATWOOT_ACCOUNT_ID e CHATWOOT_TOKEN');
  console.error(`   (.env procurado em: ${envFile} — existe: ${fs.existsSync(envFile)})`);
  process.exit(1);
}

// ---------- HTTP ----------
async function api(pathname, { method = 'GET', body } = {}) {
  const res = await fetch(`${URL}/api/v1/accounts/${ACCOUNT}${pathname}`, {
    method,
    headers: {
      api_access_token: TOKEN,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json;
  try { json = text ? JSON.parse(text) : null; } catch { json = text; }
  if (!res.ok) {
    throw new Error(`HTTP ${res.status} em ${pathname}: ${typeof json === 'string' ? json : JSON.stringify(json)}`);
  }
  return json;
}

// normaliza para comparação tolerante a acento/maiúsculas
function norm(s) {
  return String(s || '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .trim();
}

function fmtDate(v) {
  if (!v) return '—';
  // Chatwoot pode devolver epoch (segundos) ou ISO
  const d = typeof v === 'number' ? new Date(v * 1000) : new Date(v);
  return isNaN(d.getTime()) ? String(v) : d.toISOString();
}

async function countContactsByLabel(labelTitle) {
  try {
    const r = await api(`/contacts?labels[]=${encodeURIComponent(labelTitle)}&page=1`);
    return r?.meta?.count ?? (Array.isArray(r?.payload) ? r.payload.length : null);
  } catch (e) {
    return `erro: ${e.message}`;
  }
}

(async () => {
  console.log('🔗 Chatwoot:', URL, '| conta:', ACCOUNT);
  console.log('🔎 Procurando campanha por título contendo:', JSON.stringify(TITLE));
  console.log('—'.repeat(60));

  // 1) Lista campanhas
  const list = await api('/campaigns');
  const campaigns = Array.isArray(list) ? list : (list?.payload || []);
  if (!campaigns.length) {
    console.log('Nenhuma campanha encontrada nesta conta.');
    return;
  }

  // 2) Encontra por título (match tolerante)
  const wanted = norm(TITLE);
  let matches = campaigns.filter((c) => norm(c.title) === wanted);
  if (!matches.length) matches = campaigns.filter((c) => norm(c.title).includes(wanted));
  if (!matches.length) matches = campaigns.filter((c) => norm(c.title).includes('namorad'));

  if (!matches.length) {
    console.log('Não achei a campanha. Campanhas existentes:');
    campaigns.forEach((c) =>
      console.log(`  • [${c.id}] "${c.title}" — status=${c.campaign_status} tipo=${c.campaign_type}`)
    );
    return;
  }

  // 3) Carrega o mapa de etiquetas (id -> título) para resolver a audiência
  let labelById = {};
  try {
    const labels = await api('/labels');
    const arr = Array.isArray(labels) ? labels : (labels?.payload || []);
    arr.forEach((l) => { labelById[l.id] = l.title; });
  } catch (e) {
    console.log('⚠️  Não consegui carregar etiquetas:', e.message);
  }

  for (const c of matches) {
    console.log('\n' + '='.repeat(60));
    console.log(`📣 Campanha: "${c.title}"  (id=${c.id}, display_id=${c.display_id})`);
    console.log('='.repeat(60));
    console.log('  status        :', c.campaign_status, c.campaign_status === 'completed' ? '(concluída)' : '');
    console.log('  tipo          :', c.campaign_type);
    console.log('  habilitada    :', c.enabled);
    console.log('  inbox_id      :', c.inbox_id);
    console.log('  sender_id     :', c.sender_id ?? '—');
    console.log('  agendada em   :', fmtDate(c.scheduled_at));
    console.log('  criada em     :', fmtDate(c.created_at));
    console.log('  atualizada em :', fmtDate(c.updated_at));
    console.log('  mensagem      :', c.message ? JSON.stringify(c.message) : '—');
    console.log('  template_params presente:', c.template_params && Object.keys(c.template_params).length ? 'SIM' : 'NÃO ⚠️');
    if (c.template_params && Object.keys(c.template_params).length) {
      console.log('  template_params:', JSON.stringify(c.template_params, null, 2));
    }

    // Audiência
    const audience = Array.isArray(c.audience) ? c.audience : [];
    console.log(`\n  👥 Audiência (${audience.length} entrada(s)):`);
    let totalAlcance = 0;
    let alcanceConhecido = true;
    for (const a of audience) {
      const title = a.type === 'Label' ? (labelById[a.id] || `label#${a.id}`) : `${a.type}#${a.id}`;
      let count = '—';
      if (a.type === 'Label' && labelById[a.id]) {
        count = await countContactsByLabel(labelById[a.id]);
        if (typeof count === 'number') totalAlcance += count; else alcanceConhecido = false;
      } else {
        alcanceConhecido = false;
      }
      console.log(`    • ${a.type} "${title}" → contatos: ${count}`);
    }
    if (alcanceConhecido) {
      console.log(`  → Alcance total (soma das etiquetas, pode haver sobreposição): ${totalAlcance}`);
    }

    // Diagnóstico de envio
    console.log('\n  🩺 Diagnóstico de envio:');
    const problemas = [];
    if (c.campaign_status !== 'completed') {
      problemas.push('status NÃO é "completed" — a campanha ainda não foi disparada.');
    }
    if (!(c.template_params && Object.keys(c.template_params).length)) {
      problemas.push('template_params VAZIO — o serviço pula TODOS os contatos sem template (nenhum envio).');
    }
    // Header de mídia sem URL → header descartado em build_header_params (next if value.blank?).
    // Se o template aprovado exige imagem no header, a Meta rejeita cada envio (erro engolido).
    const header = c.template_params?.processed_params?.header;
    if (header && header.media_type && !header.media_url) {
      problemas.push(
        `header.media_type="${header.media_type}" mas media_url VAZIO — se o template exige imagem no cabeçalho, ` +
        'a Meta rejeita TODOS os envios e o erro é engolido (oneoff_campaign_service.rb:90).'
      );
    }
    if (alcanceConhecido && totalAlcance === 0) {
      problemas.push('Audiência resolve para 0 contatos — não havia para quem enviar.');
    }
    if (!audience.length) {
      problemas.push('Sem audiência configurada.');
    }

    console.log('     • O status "completed" é definido ANTES do envio (oneoff_campaign_service.rb:7),');
    console.log('       então "concluída" por si só NÃO comprova que as mensagens saíram.');
    if (problemas.length) {
      console.log('     ⚠️  Sinais de que provavelmente NÃO enviou:');
      problemas.forEach((p) => console.log('        - ' + p));
    } else {
      console.log('     ✅ Configuração consistente (status completed, template e audiência presentes).');
      console.log('        Para confirmar 100%, é preciso checar os logs/mensagens enviadas no WhatsApp.');
    }
  }

  console.log('\n' + '—'.repeat(60));
  console.log('Obs.: envios WhatsApp via send_template não criam conversa nesta conta,');
  console.log('então a confirmação definitiva de entrega está nos logs do Rails / no painel da Meta.');
})().catch((e) => {
  console.error('💥 Erro:', e.message);
  process.exit(1);
});
