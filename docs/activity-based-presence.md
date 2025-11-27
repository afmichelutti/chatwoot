# Activity-Based Presence - Documentação

## Visão Geral

Sistema automático que gerencia o status de disponibilidade dos agentes baseado em sua atividade de envio de mensagens.

## Como Funciona

### Atualização Imediata (ONLINE)
- Quando o agente **envia uma mensagem**, o status é atualizado **IMEDIATAMENTE** para ONLINE
- Não precisa esperar o job rodar
- Implementado via callback `after_create_commit` no model Message

### Atualização Periódica (OFFLINE)
- Job roda **a cada 1 minuto** via Sidekiq Cron para verificar inatividade
- Processa apenas agentes com `auto_offline: false`
- Processa apenas contas com `activity_based_presence_enabled: true`

### Regras de Negócio

#### REGRA 1: Enviou mensagem recentemente → ONLINE
- Se o agente enviou mensagem dentro do `inactivity_timeout_minutes`
- Status é alterado para **ONLINE**

#### REGRA 2: BUSY há muito tempo → OFFLINE
- Se o agente está em BUSY há mais de `busy_timeout_hours`
- Força status para **OFFLINE** (assume que esqueceu de voltar)

#### REGRA 3: BUSY recente → Manter BUSY
- Se o agente está em BUSY há menos de `busy_timeout_hours`
- Mantém status **BUSY** (respeita a pausa intencional)

#### REGRA 4: Sem mensagem há muito tempo → OFFLINE
- Se não enviou mensagem há mais de `inactivity_timeout_minutes`
- Status é alterado para **OFFLINE**

## Configuração

### Por Conta (Account Settings)

**Via Interface Web (Recomendado):**
1. Acesse **Settings → Account Settings → Activity-Based Presence**
2. Habilite "Presença Baseada em Atividade"
3. Configure os timeouts
4. **Automaticamente** todos os agentes terão `auto_offline: false`

**Via Rails Console:**
```ruby
account = Account.find(1)

# Habilitar o sistema (isso automaticamente configura auto_offline: false para todos os agentes)
account.update!(activity_based_presence_enabled: true)

# Configurar timeouts
account.update!(
  activity_based_presence_config: {
    inactivity_timeout_minutes: 3,  # Minutos sem mensagem → offline
    busy_timeout_hours: 3            # Horas em BUSY → força offline
  }
)
```

### Por Agente (User Settings)

**Comportamento Padrão:**
- Quando você habilita Activity-Based Presence na conta, **TODOS os agentes** são automaticamente configurados com `auto_offline: false`
- Isso significa que todos participam do sistema automaticamente

**Exceções (Opt-out):**
Se algum agente específico preferir gerenciar seu status manualmente (ex: gerentes, supervisores):

```ruby
account_user = AccountUser.find_by(account_id: 1, user_id: 1)

# Desabilitar para este agente (gerencia status manualmente)
account_user.update!(auto_offline: true)

# Re-habilitar para este agente (volta a ser gerenciado automaticamente)
account_user.update!(auto_offline: false)
```

## Arquivos Principais

### Jobs
- **Job Periódico:** `app/jobs/activity_based_presence_job.rb` (Fila: `low`, A cada 1 minuto)
- **Job Imediato:** `app/jobs/update_agent_presence_job.rb` (Fila: `high`, Assíncrono)

### Callback
- **Model Message:** `app/models/message.rb` (Método: `update_agent_presence_on_message`)

### Migration
- `db/migrate/20250118000000_add_activity_based_presence_to_accounts.rb`

### Interface Web
- `app/javascript/dashboard/routes/dashboard/settings/account/components/ActivityBasedPresence.vue`

## Bugs Corrigidos

### 1. Filtro de message_type com Enum
**Problema:** O filtro `message_type: Message.message_types[:outgoing]` não funcionava porque o enum estava armazenando strings ao invés de integers.

**Solução:** Removido o filtro de `message_type`. O filtro `sender_type: 'User'` já garante que são mensagens enviadas pelo agente.

### 2. Conflito de ORDER BY
**Problema:** O `default_scope` da model Message estava causando conflito com nosso ORDER BY:
```sql
ORDER BY "messages"."created_at" ASC, created_at DESC
```
Isso fazia retornar sempre a mensagem mais ANTIGA ao invés da mais RECENTE.

**Solução:** Usar `.reorder()` ao invés de `.order()` para forçar a remoção do default_scope:
```ruby
Message.where(...).reorder('created_at DESC').limit(1).first
```

### 3. Performance do Callback Imediato
**Problema:** O callback `update_agent_presence_on_message` estava fazendo o `update!` diretamente dentro do `after_create_commit`, causando:
- Lentidão de 3+ segundos na criação da mensagem
- Erros 500 ocasionais
- Lock de transação no banco de dados
- Delay de 15 segundos para atualizar o status

**Solução:** Mover o update para um job assíncrono na fila `high`:
```ruby
# app/models/message.rb
def update_agent_presence_on_message
  UpdateAgentPresenceJob.perform_later(account_id, sender_id)
end

# app/jobs/update_agent_presence_job.rb
class UpdateAgentPresenceJob < ApplicationJob
  queue_as :high # Alta prioridade
  # ... faz o update do status
end
```

**Resultado:**
- Mensagem criada sem delay
- Status atualizado em < 1 segundo (processamento assíncrono)
- Sem erros 500
- Sem locks de transação

## Testes e Debugging

### Script de Teste
Execute no Rails Console:
```ruby
load 'test_activity_job.rb'
```

Isso mostra:
- Configuração da conta
- Último envio de mensagem
- Qual regra seria aplicada
- Qual seria o novo status

### Logs do Sidekiq
Acompanhe os logs no Terminal 2 (Sidekiq):
```
[ActivityPresence] Starting job...
[ActivityPresence] Processing account 1 (Caper Advogados)
[ActivityPresence] desenvolvimento@omniflex.com.br: last_msg=2025-11-26 18:59:23 UTC, timeout=2025-11-26 18:56:30 UTC, current_status=online
[ActivityPresence] desenvolvimento@omniflex.com.br: REGRA 1 aplicada → ONLINE
[ActivityPresence] Account 1: 0 agents updated
[ActivityPresence] Job completed
```

### Verificar Configuração
```ruby
# Ver jobs agendados
Sidekiq::Cron::Job.all.map(&:name)

# Ver configuração da conta
account = Account.find(1)
puts account.activity_based_presence_enabled
puts account.activity_based_presence_config

# Ver configuração do agente
account_user = AccountUser.find_by(account_id: 1, user_id: 1)
puts account_user.auto_offline  # false = gerenciado automaticamente
puts account_user.availability   # online/offline/busy
```

### Forçar Execução Manual
```ruby
# No Rails Console
ActivityBasedPresenceJob.perform_now
```

## Fluxo de Exemplo

1. **Agente envia mensagem às 10:00**
   - **IMEDIATAMENTE**: status muda para **ONLINE** (via callback)
   - Não precisa esperar job rodar

2. **Agente não envia mais mensagens**
   - Job roda às 10:01 → ainda ONLINE (< 3 min)
   - Job roda às 10:02 → ainda ONLINE (< 3 min)
   - Job roda às 10:03 → ainda ONLINE (< 3 min)
   - Job roda às 10:04 → **OFFLINE** (> 3 min)

3. **Agente muda para BUSY manualmente às 10:05**
   - Jobs continuam rodando mas respeitam BUSY
   - REGRA 3: mantém BUSY

4. **Agente esquece de voltar de BUSY**
   - Job roda às 13:06 (3+ horas depois)
   - REGRA 2: força **OFFLINE**

## Boas Práticas

1. **Timeout de Inatividade:**
   - Recomendado: 3-5 minutos
   - Muito curto: agente fica offline enquanto lê mensagens
   - Muito longo: demora para marcar como offline

2. **Timeout de BUSY:**
   - Recomendado: 2-4 horas
   - Permite pausas para almoço/reuniões
   - Evita agentes "presos" em BUSY

3. **Auto Offline:**
   - Gerentes/supervisores: `auto_offline: true` (gerenciam status manualmente)
   - Agentes ativos: `auto_offline: false` (gerenciado automaticamente)

## Solução de Problemas

### Agente não fica online após enviar mensagem
1. Verificar `auto_offline: false`
2. Verificar `activity_based_presence_enabled: true` na conta
3. Verificar logs do Sidekiq
4. Rodar `load 'test_activity_job.rb'` no console

### Job não está rodando
1. Verificar no console: `Sidekiq::Cron::Job.find('activity_based_presence_job')`
2. Reiniciar Sidekiq
3. Verificar `config/schedule.yml`

### Mensagens não estão sendo encontradas
1. Verificar no console se as mensagens existem
2. Verificar `sender_type: 'User'` e `sender_id`
3. Rodar script de teste para debug

## Autor

Implementado em 2025-01-18
Bugs corrigidos em 2025-11-26
