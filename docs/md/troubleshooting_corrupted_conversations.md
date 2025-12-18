# Troubleshooting: Conversas Corrompidas (Erro 500)

**Data:** 18 de Dezembro de 2025
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

| Data | Usuário | Tipo de Lista | Conversa ID | Status |
|------|---------|---------------|-------------|---------|
| 2025-12-18 | Cloves | "Minhas conversas" | #164207 (ID: 278928) | ✅ Resolvido |
| 2025-12-18 | Cloves | "Não atribuídas" | #159895 (ID: 265294) | ✅ Resolvido |

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

### Problema: Relacionamento Órfão

Conversas apontam para `contact_inbox_id` que **não existe mais** na tabela `contact_inboxes`.

**Cenário:**
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

### Por que isso acontece?

1. **Foreign Key sem CASCADE**: A FK não tem `ON DELETE CASCADE`
2. **Deleção manual**: ContactInbox deletado manualmente via SQL ou script
3. **Bug em migrations**: Alguma migration antiga deletou contact_inboxes sem atualizar conversations
4. **Race condition**: Deleção de inbox enquanto conversa estava sendo criada

---

## 🔬 Como Diagnosticar

### Método 1: Via Rails Runner (Recomendado)

Crie um arquivo `find_corrupted_conversations.rb`:

```ruby
# find_corrupted_conversations.rb
# Encontra todas as conversas corrompidas em uma conta

account_id = ARGV[0]&.to_i || 1

puts "==== Buscando conversas corrompidas na conta #{account_id} ===="

account = Account.find(account_id)

# Buscar conversas open/pending
conversations = account.conversations.where(status: [:open, :pending])

puts "Total de conversas abertas/pendentes: #{conversations.count}"
puts "\n==== Verificando integridade ===="

corrupted = []

conversations.find_each do |conv|
  # Verificar se contact_inbox existe
  if conv.contact_inbox_id.present? && conv.contact_inbox.nil?
    corrupted << {
      id: conv.id,
      display_id: conv.display_id,
      contact_inbox_id: conv.contact_inbox_id,
      assignee_id: conv.assignee_id,
      status: conv.status
    }

    print "❌ "
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
  puts "\n==== Conversas Corrompidas ===="
  corrupted.each do |c|
    assignee = c[:assignee_id] ? "Agente #{c[:assignee_id]}" : "Não atribuída"
    puts "  ##{c[:display_id]} (ID: #{c[:id]}) - #{assignee} - contact_inbox_id: #{c[:contact_inbox_id]}"
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

### 1. Encontrar todas as conversas corrompidas

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

### 2. Estatísticas por conta

```sql
-- Quantas conversas corrompidas por conta
SELECT
    c.account_id,
    a.name AS account_name,
    COUNT(c.id) AS corrupted_count
FROM conversations c
LEFT JOIN contact_inboxes ci ON c.contact_inbox_id = ci.id
LEFT JOIN accounts a ON c.account_id = a.id
WHERE c.status IN (0, 2)
  AND c.contact_inbox_id IS NOT NULL
  AND ci.id IS NULL
GROUP BY c.account_id, a.name
ORDER BY corrupted_count DESC;
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

### 4. Resolver em massa via SQL

```sql
-- CUIDADO: Isso modifica dados em produção!

-- Resolver conversas corrompidas
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

-- Verificar quantas foram atualizadas
SELECT 'Updated ' || ROW_COUNT() || ' conversations';
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

**Última atualização:** 2025-12-18
**Autor:** Equipe Omniflex + Claude
**Status:** ✅ Documentado e testado
