# Troubleshooting: Conversas Corrompidas (Erro 500)

**Data:** 18-19 de Dezembro de 2025
**Versão:** Chatwoot v4.7.0-custom
**Ambiente:** Produção (Omniflex)

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Sintomas](#sintomas)
3. [Causa Raiz](#causa-raiz)
4. [Como Diagnosticar](#como-diagnosticar)
5. [Soluções](#soluções)
6. [Prevenção](#prevenção)
7. [Queries SQL Úteis](#queries-sql-úteis)

---

## 🔍 Visão Geral

Este documento descreve um problema recorrente onde conversas com dados órfãos causam erro 500 ao tentar listar conversas no Chatwoot.

### Histórico de Ocorrências

| Data | Account | Tipo de Lista | Conversa IDs | Tipo de Corrupção | Status |
|------|---------|---------------|--------------|-------------------|---------|
| 2025-12-18 | 1 (Cloves) | "Minhas conversas" | #164207 (ID: 278928) | contact_inbox órfão | ✅ Resolvido |
| 2025-12-18 | 1 (Cloves) | "Não atribuídas" | #159895 (ID: 265294) | contact_inbox órfão | ✅ Resolvido |
| 2025-12-19 | 56 | Todos filtros | IDs: 281760, 281761, 281762, 281764 | contact + contact_inbox órfãos | ✅ Resolvido |
| 2025-12-19 | Múltiplas (1, 59) | - | 14 conversas | team órfão + status inválido (59) | ✅ Resolvido |

---

## 🚨 Sintomas

### 1. Erro 500 ao listar conversas

**Endpoints afetados:**
- `GET /api/v1/accounts/:account_id/conversations?status=open&assignee_type=me`
- `GET /api/v1/accounts/:account_id/conversations?status=open&assignee_type=unassigned`
- `GET /api/v1/accounts/:account_id/conversations?status=open&assignee_type=all`

**Resposta:**
```json
{
  "status": 500,
  "error": "Internal Server Error"
}
```

**Logs do servidor:**
```
NoMethodError: undefined method 'source_id' for nil
at app/models/message.rb:171 in 'conversation_push_event_data'
```

### 2. Comportamento na UI

- ✅ Login funciona normalmente
- ✅ Outras páginas carregam
- ❌ Lista de conversas não carrega (spinner infinito)
- ❌ Console do navegador mostra erro 500

---

## 🐛 Causa Raiz

### Problema: Relacionamentos Órfãos

Conversas apontam para IDs de registros que **não existem mais** em suas respectivas tabelas.

#### Tipos de Corrupção Identificados:

| Tipo | Campo | Tabela Órfã | Risco de Erro 500 |
|------|-------|-------------|-------------------|
| **contact_inbox órfão** | `contact_inbox_id` | `contact_inboxes` | 🔴 **ALTO** |
| **contact órfão** | `contact_id` | `contacts` | 🔴 **ALTO** |
| **inbox órfão** | `inbox_id` | `inboxes` | 🔴 **ALTO** |
| **assignee órfão** | `assignee_id` | `users` | 🟡 **MÉDIO** |
| **team órfão** | `team_id` | `teams` | 🟡 **MÉDIO** |
| **status inválido** | `status` | - | 🔴 **MUITO ALTO** |

#### Cenário Exemplo (contact_inbox órfão):

```
conversations.contact_inbox_id = 276584
contact_inboxes.id = 276584 (DELETADO)
```

Quando o Rails tenta fazer:
```ruby
conversation.contact_inbox.source_id
```

Retorna:
```
nil.source_id  # => NoMethodError
```

#### Cenário Exemplo (status inválido):

```
conversations.status = 59  # Valores válidos: 0, 1, 2, 3
```

Status válidos:
- `0` = open
- `1` = resolved
- `2` = pending
- `3` = snoozed

Qualquer outro valor causa comportamento imprevisível.

### Por que isso acontece?

1. **Foreign Key sem CASCADE**: As FKs não têm `ON DELETE CASCADE` ou `ON DELETE SET NULL`
2. **Deleção manual**: Registros deletados manualmente via SQL ou script
3. **Bug em migrations**: Migrations antigas deletaram registros sem atualizar conversations
4. **Race condition**: Deleção de registros enquanto conversa estava sendo criada/atualizada
5. **Importação/Sync incorreta**: Dados corrompidos durante importação ou sincronização
6. **Bug em código**: Código antigo que modifica status diretamente sem validação

---

## 🔬 Como Diagnosticar

### Método 1: Via Rails Runner (Recomendado)

Crie um arquivo `find_corrupted_conversations.rb`:

```ruby
# find_corrupted_conversations.rb
# Encontra TODAS as conversas corrompidas em uma conta (verifica TODOS os relacionamentos)

account_id = ARGV[0]&.to_i || 1

puts "==== Buscando conversas corrompidas na conta #{account_id} ===="

account = Account.find(account_id)

# Buscar conversas open/pending
conversations = account.conversations.where(status: [:open, :pending])

puts "Total de conversas abertas/pendentes: #{conversations.count}"
puts "\n==== Verificando integridade ===="

corrupted = []
orphan_types = {
  contact: [],
  inbox: [],
  contact_inbox: [],
  assignee: [],
  team: []
}

conversations.find_each do |conv|
  issues = []

  # Verificar contact órfão
  if conv.contact_id.present? && conv.contact.nil?
    issues << 'contact'
    orphan_types[:contact] << conv.id
  end

  # Verificar inbox órfão
  if conv.inbox_id.present? && conv.inbox.nil?
    issues << 'inbox'
    orphan_types[:inbox] << conv.id
  end

  # Verificar contact_inbox órfão
  if conv.contact_inbox_id.present? && conv.contact_inbox.nil?
    issues << 'contact_inbox'
    orphan_types[:contact_inbox] << conv.id
  end

  # Verificar assignee órfão
  if conv.assignee_id.present? && conv.assignee.nil?
    issues << 'assignee'
    orphan_types[:assignee] << conv.id
  end

  # Verificar team órfão
  if conv.team_id.present? && conv.team.nil?
    issues << 'team'
    orphan_types[:team] << conv.id
  end

  if issues.any?
    corrupted << {
      id: conv.id,
      display_id: conv.display_id,
      status: conv.status,
      issues: issues
    }
    print "❌"
  else
    print "."
  end

  # Flush output a cada 50 conversas
  STDOUT.flush if corrupted.length % 50 == 0
end

puts "\n\n==== Resultado ===="
puts "Conversas verificadas: #{conversations.count}"
puts "Conversas corrompidas: #{corrupted.length}"

if corrupted.any?
  # Mostrar estatísticas por tipo
  puts "\n==== Tipos de Corrupção ===="
  orphan_types.each do |type, ids|
    next if ids.empty?
    puts "  #{type.to_s.upcase} órfão: #{ids.length} conversas"
  end

  puts "\n==== Conversas Corrompidas ===="
  corrupted.each do |c|
    puts "  ##{c[:display_id]} (ID: #{c[:id]}) - Problemas: #{c[:issues].join(', ')}"
  end

  puts "\n==== Comando para resolver ===="
  puts "Conversation.where(id: [#{corrupted.map { |c| c[:id] }.join(', ')}]).update_all(status: 1)"
else
  puts "✅ Nenhuma conversa corrompida encontrada!"
end
```

**Executar:**
```bash
bundle exec rails runner find_corrupted_conversations.rb [ACCOUNT_ID]
```

**Exemplo de output:**
```
==== Buscando conversas corrompidas na conta 1 ====
Total de conversas abertas/pendentes: 150
==== Verificando integridade ====
..........................❌.....................

==== Resultado ====
Conversas verificadas: 150
Conversas corrompidas: 1

==== Conversas Corrompidas ====
  #159895 (ID: 265294) - Não atribuída - contact_inbox_id: 276584

==== Comando para resolver ====
Conversation.where(id: [265294]).update_all(status: 1)
```

### Método 2: Via Rails Console

```ruby
# 1. Conectar ao console
bundle exec rails console

# 2. Encontrar conversas corrompidas
account = Account.find(1)

corrupted = account.conversations
  .where(status: [:open, :pending])
  .select { |c| c.contact_inbox_id.present? && c.contact_inbox.nil? }

puts "Encontradas #{corrupted.length} conversas corrompidas:"
corrupted.each do |c|
  puts "  ##{c.display_id} (ID: #{c.id})"
end

# 3. Resolver
corrupted.each do |c|
  c.update!(status: :resolved)
  puts "✅ Conversa ##{c.display_id} resolvida"
end
```

### Método 3: Via SQL Direto

```sql
-- Conectar ao banco
psql -h pg.slave.omniflex.com.br -p 25060 -U postgres -d chatwoot_new

-- Executar query
SELECT
    c.id,
    c.display_id,
    c.status,
    c.assignee_id,
    c.contact_inbox_id,
    c.created_at
FROM conversations c
LEFT JOIN contact_inboxes ci ON c.contact_inbox_id = ci.id
WHERE c.account_id = 1
  AND c.status IN (0, 2)  -- 0=open, 2=pending
  AND c.contact_inbox_id IS NOT NULL
  AND ci.id IS NULL
ORDER BY c.created_at DESC;
```

**Output esperado:**
```
 id     | display_id | status | assignee_id | contact_inbox_id | created_at
--------+------------+--------+-------------+------------------+------------
 265294 | 159895     | 0      |             | 276584           | 2025-11-19
```

---

## ✅ Soluções

### Solução 1: Via Rails Console (Recomendado)

**Vantagens:**
- ✅ Seguro
- ✅ Validações do Rails
- ✅ Logs/auditoria
- ✅ Callbacks executados

**Desvantagens:**
- ⏱️ Mais lento para múltiplas conversas

```ruby
# 1. Abrir Rails Console
bundle exec rails console

# 2. Resolver conversa específica
conv = Conversation.find(265294)
conv.status = :resolved
conv.save(validate: false)

# Ou múltiplas de uma vez
ids = [265294, 278928]
Conversation.where(id: ids).find_each do |conv|
  conv.update!(status: :resolved)
end
```

### Solução 2: Via SQL (Update em Massa)

**Vantagens:**
- ⚡ Muito rápido
- 📊 Ideal para múltiplas conversas

**Desvantagens:**
- ⚠️ Pula validações
- ⚠️ Não executa callbacks
- ⚠️ Não gera eventos/notificações

```ruby
# Via Rails Console (usando ActiveRecord.connection)
Conversation.where(id: [265294, 278928]).update_all(status: 1)
```

**Ou via SQL puro:**
```sql
-- Resolver conversas específicas
UPDATE conversations
SET status = 1, updated_at = NOW()
WHERE id IN (265294, 278928);

-- OU resolver TODAS as corrompidas
UPDATE conversations
SET status = 1, updated_at = NOW()
WHERE id IN (
    SELECT c.id
    FROM conversations c
    LEFT JOIN contact_inboxes ci ON c.contact_inbox_id = ci.id
    WHERE c.status IN (0, 2)
      AND c.contact_inbox_id IS NOT NULL
      AND ci.id IS NULL
);
```

### Solução 3: Via Rails Runner (Script Automatizado)

**Ideal para:** Execução agendada (cron job)

Crie `fix_corrupted_conversations.rb`:

```ruby
# fix_corrupted_conversations.rb
# Resolve automaticamente conversas corrompidas

ACCOUNT_ID = ARGV[0]&.to_i || 1
DRY_RUN = ARGV[1] == '--dry-run'

puts "==== Corrigindo conversas corrompidas (Account #{ACCOUNT_ID}) ===="
puts "Modo: #{DRY_RUN ? 'DRY RUN (simulação)' : 'PRODUÇÃO'}"

account = Account.find(ACCOUNT_ID)

# Encontrar conversas corrompidas
sql = <<-SQL
  SELECT c.id
  FROM conversations c
  LEFT JOIN contact_inboxes ci ON c.contact_inbox_id = ci.id
  WHERE c.account_id = #{account.id}
    AND c.status IN (0, 2)
    AND c.contact_inbox_id IS NOT NULL
    AND ci.id IS NULL
SQL

corrupted_ids = ActiveRecord::Base.connection.execute(sql).map { |r| r['id'] }

puts "Conversas corrompidas encontradas: #{corrupted_ids.length}"

if corrupted_ids.empty?
  puts "✅ Nenhuma conversa corrompida!"
  exit 0
end

corrupted_ids.each do |id|
  conv = Conversation.find(id)
  puts "  Conversa ##{conv.display_id} (ID: #{id})"
end

unless DRY_RUN
  puts "\n==== Resolvendo conversas ===="
  count = Conversation.where(id: corrupted_ids).update_all(status: 1)
  puts "✅ #{count} conversas resolvidas com sucesso!"
end

puts "\n==== Concluído ===="
```

**Executar:**
```bash
# Simular (não modifica nada)
bundle exec rails runner fix_corrupted_conversations.rb 1 --dry-run

# Executar de verdade
bundle exec rails runner fix_corrupted_conversations.rb 1
```

---

## 🛡️ Prevenção

### 1. Fix Permanente no Código (IMPLEMENTADO)

**Arquivo:** `app/models/message.rb` (linhas 166-175)

**Antes:**
```ruby
def conversation_push_event_data
  {
    assignee_id: conversation.assignee_id,
    unread_count: conversation.unread_incoming_messages.count,
    last_activity_at: conversation.last_activity_at.to_i,
    contact_inbox: { source_id: conversation.contact_inbox.source_id }
  }
end
```

**Depois:**
```ruby
def conversation_push_event_data
  data = {
    assignee_id: conversation.assignee_id,
    unread_count: conversation.unread_incoming_messages.count,
    last_activity_at: conversation.last_activity_at.to_i
  }
  # Add contact_inbox only if it exists (prevent nil error)
  data[:contact_inbox] = { source_id: conversation.contact_inbox.source_id } if conversation.contact_inbox.present?
  data
end
```

✅ **Resultado:** Mesmo com dados corrompidos, não causa mais erro 500!

### 2. Adicionar Foreign Key com CASCADE (Recomendado)

**Migration:**
```ruby
# db/migrate/YYYYMMDDHHMMSS_add_cascade_to_conversations_contact_inbox_fk.rb
class AddCascadeToConversationsContactInboxFk < ActiveRecord::Migration[7.1]
  def up
    # Remove FK antiga
    remove_foreign_key :conversations, :contact_inboxes if foreign_key_exists?(:conversations, :contact_inboxes)

    # Adiciona nova FK com ON DELETE SET NULL
    add_foreign_key :conversations, :contact_inboxes,
                    column: :contact_inbox_id,
                    on_delete: :nullify
  end

  def down
    remove_foreign_key :conversations, :contact_inboxes
    add_foreign_key :conversations, :contact_inboxes
  end
end
```

**Executar:**
```bash
bundle exec rails db:migrate
```

✅ **Resultado:** Quando um `contact_inbox` for deletado, `conversations.contact_inbox_id` será automaticamente setado para `NULL`.

### 3. Validação no Model

**Arquivo:** `app/models/conversation.rb`

```ruby
# Adicionar validação (OPCIONAL - pode causar problemas em importações)
validates :contact_inbox, presence: true, on: :create
```

⚠️ **Cuidado:** Isso pode quebrar criação de conversas se houver bugs no código.

### 4. Job de Limpeza Periódica

**Arquivo:** `app/jobs/cleanup_corrupted_conversations_job.rb`

```ruby
class CleanupCorruptedConversationsJob < ApplicationJob
  queue_as :low_priority

  def perform
    Rails.logger.info "Starting corrupted conversations cleanup"

    Account.find_each do |account|
      cleanup_account(account)
    end

    Rails.logger.info "Corrupted conversations cleanup completed"
  end

  private

  def cleanup_account(account)
    sql = <<-SQL
      SELECT c.id
      FROM conversations c
      LEFT JOIN contact_inboxes ci ON c.contact_inbox_id = ci.id
      WHERE c.account_id = #{account.id}
        AND c.status IN (0, 2)
        AND c.contact_inbox_id IS NOT NULL
        AND ci.id IS NULL
    SQL

    corrupted_ids = ActiveRecord::Base.connection.execute(sql).map { |r| r['id'] }

    return if corrupted_ids.empty?

    count = Conversation.where(id: corrupted_ids).update_all(status: 1)

    Rails.logger.warn "Account #{account.id}: Resolved #{count} corrupted conversations"

    # Notificar admins (opcional)
    # AdminMailer.corrupted_conversations_fixed(account, count).deliver_later
  end
end
```

**Agendar no Sidekiq:**

```ruby
# config/initializers/sidekiq_scheduler.rb (se usar sidekiq-scheduler)
CleanupCorruptedConversationsJob.perform_async

# Ou via cron (config/schedule.rb se usar whenever gem)
every 1.day, at: '3:00 am' do
  runner "CleanupCorruptedConversationsJob.perform_now"
end
```

---

## 📊 Queries SQL Úteis

### 0. Query COMPLETA - Encontrar TODOS os Tipos de Corrupção

```sql
-- Query completa que verifica TODOS os tipos de relacionamentos órfãos
SELECT
    c.id,
    c.display_id,
    c.account_id,
    c.status,
    c.created_at,
    -- Identificar tipo de problema
    CASE
        WHEN c.contact_id IS NOT NULL AND ct.id IS NULL THEN 'CONTACT_ORPHAN'
        ELSE 'OK'
    END AS contact_status,
    CASE
        WHEN c.inbox_id IS NOT NULL AND ib.id IS NULL THEN 'INBOX_ORPHAN'
        ELSE 'OK'
    END AS inbox_status,
    CASE
        WHEN c.contact_inbox_id IS NOT NULL AND ci.id IS NULL THEN 'CONTACT_INBOX_ORPHAN'
        ELSE 'OK'
    END AS contact_inbox_status,
    CASE
        WHEN c.assignee_id IS NOT NULL AND u.id IS NULL THEN 'ASSIGNEE_ORPHAN'
        ELSE 'OK'
    END AS assignee_status,
    CASE
        WHEN c.team_id IS NOT NULL AND t.id IS NULL THEN 'TEAM_ORPHAN'
        ELSE 'OK'
    END AS team_status,
    CASE
        WHEN c.status NOT IN (0, 1, 2, 3) THEN 'INVALID_STATUS'
        ELSE 'OK'
    END AS status_validation
FROM conversations c
LEFT JOIN contacts ct ON c.contact_id = ct.id
LEFT JOIN inboxes ib ON c.inbox_id = ib.id
LEFT JOIN contact_inboxes ci ON c.contact_inbox_id = ci.id
LEFT JOIN users u ON c.assignee_id = u.id
LEFT JOIN teams t ON c.team_id = t.id
WHERE c.status IN (0, 2)  -- open, pending (ou remover para ver todas)
  AND (
    (c.contact_id IS NOT NULL AND ct.id IS NULL) OR
    (c.inbox_id IS NOT NULL AND ib.id IS NULL) OR
    (c.contact_inbox_id IS NOT NULL AND ci.id IS NULL) OR
    (c.assignee_id IS NOT NULL AND u.id IS NULL) OR
    (c.team_id IS NOT NULL AND t.id IS NULL) OR
    c.status NOT IN (0, 1, 2, 3)  -- Status inválido
  )
ORDER BY c.account_id, c.id;
```

### 1. Encontrar conversas corrompidas (apenas contact_inbox órfão)

```sql
-- Conversas com contact_inbox órfão
SELECT
    c.id,
    c.display_id,
    c.status,
    c.assignee_id,
    c.contact_inbox_id,
    c.created_at,
    c.account_id
FROM conversations c
LEFT JOIN contact_inboxes ci ON c.contact_inbox_id = ci.id
WHERE c.status IN (0, 2)  -- open, pending
  AND c.contact_inbox_id IS NOT NULL
  AND ci.id IS NULL
ORDER BY c.created_at DESC;
```

### 2. Estatísticas COMPLETAS por conta (recomendado)

```sql
-- Quantas conversas corrompidas por conta (TODOS os tipos)
SELECT
    c.account_id,
    a.name AS account_name,
    COUNT(c.id) AS total_corrupted,
    -- Contar por tipo
    COUNT(CASE WHEN c.contact_id IS NOT NULL AND ct.id IS NULL THEN 1 END) AS contact_orphan,
    COUNT(CASE WHEN c.inbox_id IS NOT NULL AND ib.id IS NULL THEN 1 END) AS inbox_orphan,
    COUNT(CASE WHEN c.contact_inbox_id IS NOT NULL AND ci.id IS NULL THEN 1 END) AS contact_inbox_orphan,
    COUNT(CASE WHEN c.assignee_id IS NOT NULL AND u.id IS NULL THEN 1 END) AS assignee_orphan,
    COUNT(CASE WHEN c.team_id IS NOT NULL AND t.id IS NULL THEN 1 END) AS team_orphan,
    COUNT(CASE WHEN c.status NOT IN (0, 1, 2, 3) THEN 1 END) AS invalid_status,
    -- Listar IDs (primeiros 20)
    array_agg(c.id ORDER BY c.id) FILTER (WHERE c.id IS NOT NULL) AS conversation_ids
FROM conversations c
LEFT JOIN contacts ct ON c.contact_id = ct.id
LEFT JOIN inboxes ib ON c.inbox_id = ib.id
LEFT JOIN contact_inboxes ci ON c.contact_inbox_id = ci.id
LEFT JOIN users u ON c.assignee_id = u.id
LEFT JOIN teams t ON c.team_id = t.id
LEFT JOIN accounts a ON c.account_id = a.id
WHERE c.status IN (0, 2)  -- open, pending
  AND (
    (c.contact_id IS NOT NULL AND ct.id IS NULL) OR
    (c.inbox_id IS NOT NULL AND ib.id IS NULL) OR
    (c.contact_inbox_id IS NOT NULL AND ci.id IS NULL) OR
    (c.assignee_id IS NOT NULL AND u.id IS NULL) OR
    (c.team_id IS NOT NULL AND t.id IS NULL) OR
    c.status NOT IN (0, 1, 2, 3)
  )
GROUP BY c.account_id, a.name
ORDER BY total_corrupted DESC;
```

### 3. Verificar integridade completa

```sql
-- Verificar todos os relacionamentos órfãos
SELECT
    c.id AS conversation_id,
    c.display_id,
    c.status,
    CASE
        WHEN c.contact_inbox_id IS NULL THEN 'contact_inbox_id NULL'
        WHEN ci.id IS NULL THEN 'contact_inbox ORPHANED'
        ELSE 'OK'
    END AS contact_inbox_status,
    CASE
        WHEN c.contact_id IS NULL THEN 'contact_id NULL'
        WHEN ct.id IS NULL THEN 'contact ORPHANED'
        ELSE 'OK'
    END AS contact_status,
    CASE
        WHEN c.inbox_id IS NULL THEN 'inbox_id NULL'
        WHEN ib.id IS NULL THEN 'inbox ORPHANED'
        ELSE 'OK'
    END AS inbox_status
FROM conversations c
LEFT JOIN contact_inboxes ci ON c.contact_inbox_id = ci.id
LEFT JOIN contacts ct ON c.contact_id = ct.id
LEFT JOIN inboxes ib ON c.inbox_id = ib.id
WHERE c.status IN (0, 2)
  AND (
    ci.id IS NULL OR
    ct.id IS NULL OR
    ib.id IS NULL
  )
ORDER BY c.created_at DESC;
```

### 4. Resolver em massa via SQL (TODOS os tipos de corrupção)

```sql
-- CUIDADO: Isso modifica dados em produção!

-- Resolver TODAS as conversas corrompidas (todos os tipos)
UPDATE conversations
SET status = 1,  -- resolved
    updated_at = NOW()
WHERE id IN (
    SELECT c.id
    FROM conversations c
    LEFT JOIN contacts ct ON c.contact_id = ct.id
    LEFT JOIN inboxes ib ON c.inbox_id = ib.id
    LEFT JOIN contact_inboxes ci ON c.contact_inbox_id = ci.id
    LEFT JOIN users u ON c.assignee_id = u.id
    LEFT JOIN teams t ON c.team_id = t.id
    WHERE c.status NOT IN (1, 3)  -- NÃO mexer em resolved/snoozed
      AND (
        (c.contact_id IS NOT NULL AND ct.id IS NULL) OR
        (c.inbox_id IS NOT NULL AND ib.id IS NULL) OR
        (c.contact_inbox_id IS NOT NULL AND ci.id IS NULL) OR
        (c.assignee_id IS NOT NULL AND u.id IS NULL) OR
        (c.team_id IS NOT NULL AND t.id IS NULL) OR
        c.status NOT IN (0, 1, 2, 3)  -- Status inválido
      )
);

-- Verificar quantas foram atualizadas
SELECT 'Updated ' || ROW_COUNT() || ' conversations';
```

### 4b. Resolver em massa APENAS contact_inbox órfão (legado)

```sql
-- CUIDADO: Isso modifica dados em produção!

-- Resolver conversas com contact_inbox órfão
UPDATE conversations
SET status = 1,  -- resolved
    updated_at = NOW()
WHERE id IN (
    SELECT c.id
    FROM conversations c
    LEFT JOIN contact_inboxes ci ON c.contact_inbox_id = ci.id
    WHERE c.status IN (0, 2)
      AND c.contact_inbox_id IS NOT NULL
      AND ci.id IS NULL
);
```

### 5. Monitoramento contínuo

```sql
-- Query para dashboard/monitoring
-- Retorna contagem de conversas corrompidas por status

SELECT
    CASE c.status
        WHEN 0 THEN 'open'
        WHEN 1 THEN 'resolved'
        WHEN 2 THEN 'pending'
        WHEN 3 THEN 'snoozed'
        ELSE 'unknown'
    END AS status_name,
    COUNT(c.id) AS count
FROM conversations c
LEFT JOIN contact_inboxes ci ON c.contact_inbox_id = ci.id
WHERE c.contact_inbox_id IS NOT NULL
  AND ci.id IS NULL
GROUP BY c.status
ORDER BY c.status;
```

---

## 🔗 Referências

- **Bug Fix Documentation:** [bug_fixes_conversation_permissions.md](./bug_fixes_conversation_permissions.md)
- **Model:** `app/models/message.rb`
- **Model:** `app/models/conversation.rb`
- **Database Schema:** `db/schema.rb`

---

## 📝 Checklist de Troubleshooting

Quando encontrar erro 500 em conversas:

- [ ] 1. Verificar logs do servidor para confirmar `NoMethodError` em `message.rb`
- [ ] 2. Executar script de diagnóstico: `bundle exec rails runner find_corrupted_conversations.rb`
- [ ] 3. Anotar IDs das conversas corrompidas
- [ ] 4. Resolver conversas via Rails Console ou SQL
- [ ] 5. Verificar se erro 500 foi resolvido (testar na UI)
- [ ] 6. Investigar causa raiz (por que o contact_inbox foi deletado?)
- [ ] 7. Considerar adicionar FK com CASCADE se problema for recorrente
- [ ] 8. Documentar o incidente com data, usuário afetado e causa

---

**Última atualização:** 2025-12-19
**Autor:** Equipe Omniflex + Claude
**Status:** ✅ Documentado, testado e expandido com novos tipos de corrupção

**Changelog:**
- **2025-12-19:** Expandido para incluir TODOS os tipos de relacionamentos órfãos (contact, inbox, assignee, team) + status inválido
- **2025-12-18:** Versão inicial focada em contact_inbox órfão
