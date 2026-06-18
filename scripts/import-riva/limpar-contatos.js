#!/usr/bin/env node
/**
 * limpar-contatos.js
 * -------------------------------------------------------------------------
 * Lê o XLSX bagunçado de pacientes da Riva e gera um CSV limpo, pronto para
 * importar em Contatos do Chatwoot (Configurações -> Contatos -> Importar).
 *
 * O que ele faz:
 *   - Acha a linha de cabeçalho mesmo com linhas em branco no topo.
 *   - Usa a coluna "Celular" como WhatsApp (phone_number). Telefone fixo é
 *     ignorado por padrao (nao costuma ter WhatsApp).
 *   - Normaliza para E.164 brasileiro: +55 DDD 9XXXXXXXX
 *       * remove mascara/espacos/parenteses
 *       * remove DDI 55 duplicado quando aplicavel
 *       * insere o 9o digito em celulares antigos (10 digitos)
 *       * valida o DDD contra a lista oficial
 *   - Deduplica por numero final (mantem a 1a ocorrencia).
 *   - Descarta o que nao da pra consertar com seguranca e gera um relatorio
 *     de rejeitados (.rejeitados.csv).
 *   - Suporta --limit e --offset para fatiar a lista (ex.: 2000 hoje, resto
 *     amanha) sem repetir ninguem, porque a ordem e estavel.
 *   - Grava a coluna "lista" (custom attribute) com o nome do lote/etiqueta,
 *     para voce filtrar e aplicar a etiqueta em massa depois do import.
 *
 * Uso:
 *   node limpar-contatos.js [opcoes]
 *
 * Opcoes:
 *   --in <arquivo.xlsx>   Entrada  (padrao: docs/riva/relatorio_total_pacientes_cadastrados.xlsx)
 *   --out <arquivo.csv>   Saida    (padrao: docs/riva/contatos_<label>.csv)
 *   --label <nome>        Nome do lote/etiqueta (padrao: dia_namorados)
 *   --limit <n>           Quantos contatos exportar (padrao: todos)
 *   --offset <n>          Quantos pular do inicio (padrao: 0)
 *   --phone-col <nome>    Coluna do WhatsApp: celular|telefone (padrao: celular)
 *
 * Exemplos:
 *   # Hoje: os 2000 primeiros, etiqueta dia_namorados
 *   node limpar-contatos.js --limit 2000 --label dia_namorados
 *
 *   # Amanha: do 2001 em diante (proximos 2000), sem repetir os de hoje
 *   node limpar-contatos.js --offset 2000 --limit 2000 --label dia_namorados_lote2
 * -------------------------------------------------------------------------
 */

'use strict';

const path = require('path');
const fs = require('fs');
const XLSX = require('xlsx');

// ---------------------------------------------------------------------------
// DDDs validos no Brasil (ANATEL)
// ---------------------------------------------------------------------------
const VALID_DDD = new Set([
  11, 12, 13, 14, 15, 16, 17, 18, 19,
  21, 22, 24, 27, 28,
  31, 32, 33, 34, 35, 37, 38,
  41, 42, 43, 44, 45, 46, 47, 48, 49,
  51, 53, 54, 55,
  61, 62, 63, 64, 65, 66, 67, 68, 69,
  71, 73, 74, 75, 77, 79,
  81, 82, 83, 84, 85, 86, 87, 88, 89,
  91, 92, 93, 94, 95, 96, 97, 98, 99,
]);

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------
function parseArgs(argv) {
  const out = {};
  for (let i = 2; i < argv.length; i += 1) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const key = a.slice(2);
      const next = argv[i + 1];
      if (next === undefined || next.startsWith('--')) {
        out[key] = true;
      } else {
        out[key] = next;
        i += 1;
      }
    }
  }
  return out;
}

const args = parseArgs(process.argv);
const REPO_ROOT = path.resolve(__dirname, '..', '..');

const LABEL = String(args.label || 'dia_namorados').trim();
const PHONE_COL = String(args['phone-col'] || 'celular').toLowerCase();
const LIMIT = args.limit != null && args.limit !== true ? parseInt(args.limit, 10) : null;
const OFFSET = args.offset != null && args.offset !== true ? parseInt(args.offset, 10) : 0;

const IN_PATH = path.resolve(
  args.in
    ? String(args.in)
    : path.join(REPO_ROOT, 'docs', 'riva', 'relatorio_total_pacientes_cadastrados.xlsx')
);
const OUT_PATH = path.resolve(
  args.out
    ? String(args.out)
    : path.join(REPO_ROOT, 'docs', 'riva', `contatos_${LABEL}.csv`)
);
const REJECTS_PATH = OUT_PATH.replace(/\.csv$/i, '') + '.rejeitados.csv';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
const onlyDigits = (v) => String(v == null ? '' : v).replace(/\D/g, '');

function csvField(value) {
  const s = value == null ? '' : String(value);
  if (/[",\r\n]/.test(s)) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

function writeCsv(file, header, rows) {
  const lines = [header.map(csvField).join(',')];
  for (const r of rows) lines.push(r.map(csvField).join(','));
  // UTF-8 SEM BOM: o importador do Chatwoot precisa ler o header "name" limpo.
  fs.writeFileSync(file, lines.join('\r\n') + '\r\n', { encoding: 'utf8' });
}

/**
 * Normaliza um numero brasileiro de celular para E.164 (+55DDD9XXXXXXXX).
 * Retorna { ok:true, phone } ou { ok:false, motivo }.
 */
function normalizeBR(raw) {
  let d = onlyDigits(raw);
  if (!d) return { ok: false, motivo: 'vazio' };

  // Remove zeros de tronco/operadora a esquerda (ex.: 0 27 99...).
  d = d.replace(/^0+/, '');
  if (!d) return { ok: false, motivo: 'vazio' };

  // Remove DDI 55 quando o tamanho indica que ele esta presente.
  // 13 digitos = 55 + DDD + 9XXXXXXXX ; 12 = 55 + DDD + XXXXXXXX (antigo)
  if (d.startsWith('55') && (d.length === 12 || d.length === 13)) {
    d = d.slice(2);
  }

  // Agora d deve ser parte local: DDD (2) + numero (8 ou 9).
  if (d.length === 11) {
    // DDD + 9 + 8 digitos. O 3o digito tem que ser 9 (celular).
    if (d[2] !== '9') return { ok: false, motivo: 'nao_e_celular_11dig' };
  } else if (d.length === 10) {
    // DDD + 8 digitos. Celular antigo comeca em 6-9 -> insere o 9.
    if ('6789'.includes(d[2])) {
      d = d.slice(0, 2) + '9' + d.slice(2);
    } else {
      return { ok: false, motivo: 'fixo_ou_sem_9' };
    }
  } else if (d.length < 10) {
    return { ok: false, motivo: 'curto_demais_sem_ddd' };
  } else {
    return { ok: false, motivo: `tamanho_invalido_${d.length}dig` };
  }

  const ddd = parseInt(d.slice(0, 2), 10);
  if (!VALID_DDD.has(ddd)) return { ok: false, motivo: `ddd_invalido_${ddd}` };

  return { ok: true, phone: `+55${d}` };
}

// ---------------------------------------------------------------------------
// Le a planilha
// ---------------------------------------------------------------------------
if (!fs.existsSync(IN_PATH)) {
  console.error(`Arquivo de entrada nao encontrado: ${IN_PATH}`);
  process.exit(1);
}

const wb = XLSX.readFile(IN_PATH);
const ws = wb.Sheets[wb.SheetNames[0]];
const matrix = XLSX.utils.sheet_to_json(ws, { header: 1, raw: false, defval: null });

// Acha a linha de cabecalho (a que contem "Celular")
const norm = (s) => String(s == null ? '' : s).trim().toLowerCase();
let headerIdx = -1;
for (let i = 0; i < matrix.length; i += 1) {
  const cells = (matrix[i] || []).map(norm);
  if (cells.includes('celular') || cells.includes('paciente')) {
    headerIdx = i;
    break;
  }
}
if (headerIdx === -1) {
  console.error('Nao encontrei a linha de cabecalho (esperava colunas "Paciente"/"Celular").');
  process.exit(1);
}

const header = (matrix[headerIdx] || []).map(norm);
const idxName = header.indexOf('paciente');
const idxTel = header.indexOf('telefone');
const idxCel = header.indexOf('celular');
const idxPhone = PHONE_COL === 'telefone' ? idxTel : idxCel;

if (idxPhone === -1) {
  console.error(`Coluna de telefone "${PHONE_COL}" nao encontrada no cabecalho: ${header.join(', ')}`);
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Processa linhas
// ---------------------------------------------------------------------------
const valids = []; // { name, phone, identifier }
const seen = new Map(); // phone -> primeira ocorrencia (indice em valids)
const rejects = []; // { name, telefone, celular, motivo }
const reasonCount = {};

let totalRows = 0;
let dupCount = 0;

for (let i = headerIdx + 1; i < matrix.length; i += 1) {
  const row = matrix[i] || [];
  const isEmpty = row.every((c) => c == null || String(c).trim() === '');
  if (isEmpty) continue;
  totalRows += 1;

  const name = idxName >= 0 ? String(row[idxName] == null ? '' : row[idxName]).trim() : '';
  const rawTel = idxTel >= 0 ? row[idxTel] : '';
  const rawCel = idxCel >= 0 ? row[idxCel] : '';
  const rawPhone = row[idxPhone];

  const res = normalizeBR(rawPhone);
  if (!res.ok) {
    reasonCount[res.motivo] = (reasonCount[res.motivo] || 0) + 1;
    rejects.push([name, rawTel == null ? '' : rawTel, rawCel == null ? '' : rawCel, res.motivo]);
    continue;
  }

  if (seen.has(res.phone)) {
    dupCount += 1;
    continue;
  }
  seen.set(res.phone, valids.length);

  valids.push({
    name,
    phone: res.phone,
    identifier: `riva_${res.phone.replace(/\D/g, '')}`,
  });
}

// ---------------------------------------------------------------------------
// Fatiamento (offset / limit)
// ---------------------------------------------------------------------------
const start = Number.isFinite(OFFSET) && OFFSET > 0 ? OFFSET : 0;
const end = LIMIT != null && Number.isFinite(LIMIT) ? start + LIMIT : valids.length;
const slice = valids.slice(start, end);

// ---------------------------------------------------------------------------
// Escreve CSVs
// ---------------------------------------------------------------------------
writeCsv(
  OUT_PATH,
  ['name', 'phone_number', 'identifier', 'lista'],
  slice.map((c) => [c.name, c.phone, c.identifier, LABEL])
);

if (rejects.length) {
  writeCsv(REJECTS_PATH, ['paciente', 'telefone', 'celular', 'motivo'], rejects);
}

// ---------------------------------------------------------------------------
// Relatorio
// ---------------------------------------------------------------------------
const fmt = (n) => n.toLocaleString('pt-BR');
console.log('');
console.log('================ RESUMO DA LIMPEZA ================');
console.log(`Entrada............: ${IN_PATH}`);
console.log(`Coluna WhatsApp....: ${PHONE_COL}`);
console.log(`Linhas com dados...: ${fmt(totalRows)}`);
console.log(`Validos unicos.....: ${fmt(valids.length)}`);
console.log(`Duplicados removidos: ${fmt(dupCount)}`);
console.log(`Rejeitados.........: ${fmt(rejects.length)}`);
if (Object.keys(reasonCount).length) {
  console.log('  Motivos de rejeicao:');
  Object.entries(reasonCount)
    .sort((a, b) => b[1] - a[1])
    .forEach(([motivo, n]) => console.log(`    - ${motivo}: ${fmt(n)}`));
}
console.log('---------------------------------------------------');
console.log(`Etiqueta (lista)...: ${LABEL}`);
console.log(`Offset.............: ${fmt(start)}`);
console.log(`Limite.............: ${LIMIT != null ? fmt(LIMIT) : 'todos'}`);
console.log(`EXPORTADOS agora...: ${fmt(slice.length)}  (faixa ${fmt(start + 1)}..${fmt(start + slice.length)})`);
console.log(`CSV gerado.........: ${OUT_PATH}`);
if (rejects.length) console.log(`Rejeitados em......: ${REJECTS_PATH}`);
console.log('---------------------------------------------------');

const restante = valids.length - end;
if (restante > 0) {
  const proxOffset = end;
  console.log(`Ainda faltam ${fmt(restante)} contatos. Para o proximo lote rode:`);
  console.log(`  node limpar-contatos.js --offset ${proxOffset} --limit ${LIMIT != null ? LIMIT : restante} --label ${LABEL}_lote2`);
} else {
  console.log('Todos os contatos validos ja foram exportados nesta faixa.');
}
console.log('===================================================');
console.log('');
