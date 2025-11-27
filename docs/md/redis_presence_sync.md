# Redis Presence Sync - Troubleshooting Guide

## Problema

Agentes aparecem com status incorreto na UI (online/offline/busy) mesmo após atualização manual no banco de dados.

### Sintomas

- ✅ Banco de dados tem `availability = 'online'`
- ❌ UI mostra agente como "offline"
- ✅ Configuração `auto_offline = false` no banco
- ❌ Agente continua aparecendo offline após refresh
- ✅ API `/api/v1/profile` retorna status correto
- ❌ WebSocket `presence.update` envia status errado

---

## Causa Raiz

### O que aconteceu

Quando você usa métodos que **bypassam callbacks do ActiveRecord**, o Redis não é atualizado:

```ruby
# ❌ BYPASSA CALLBACKS
AccountUser.update_all(availability: 'online')
AccountUser.update_all(auto_offline: false)
AccountUser.where(...).update_columns(availability: 'online')

# ✅ DISPARA CALLBACKS
AccountUser.find(123).update!(availability: 'online')
AccountUser.where(...).find_each { |au| au.update!(availability: 'online') }
```

### Por que Redis fica desatualizado

O modelo `AccountUser` tem um callback:

```ruby
# app/models/account_user.rb:41
after_save :update_presence_in_redis, if: :saved_change_to_availability?
```

Quando você usa `update_all()`:
1. ✅ Banco de dados é atualizado
2. ❌ Callback `after_save` **não é disparado**
3. ❌ Redis mantém valor **stale** (antigo)
4. ❌ UI lê do Redis → Mostra valor errado

---

## Entendendo a Arquitetura

### Redis vs PostgreSQL (neste contexto)

| Aspecto | PostgreSQL | Redis |
|---------|-----------|-------|
| **Tipo** | Banco relacional (disco) | Cache em memória (RAM) |
| **Velocidade** | ~100ms | ~1ms |
| **Persistência** | Permanente | Volátil (apagado ao reiniciar) |
| **Uso aqui** | Fonte da verdade | Cache para performance |
| **Quando atualiza** | Via ActiveRecord | Via callbacks ou manualmente |

### Estruturas Redis Usadas

#### 1. ONLINE_PRESENCE (Sorted Set)

Armazena **quando** cada usuário enviou o último heartbeat:

```
ONLINE_PRESENCE::1::USERS
┌─────────┬────────────┐
│ user_id │ timestamp  │ ← Score (usado para ordenar)
├─────────┼────────────┤
│   10    │ 1737489600 │ ← Último heartbeat 5s atrás
│   20    │ 1737489605 │ ← Último heartbeat 10s atrás
│   30    │ 1737489550 │ ← Último heartbeat 65s atrás (expirado)
└─────────┴────────────┘
```

**Propósito**: Detectar se usuário está conectado (heartbeat < 20 segundos)

#### 2. ONLINE_STATUS (Hash)

Armazena **qual** é o status atual de cada usuário:

```
ONLINE_STATUS::1
┌─────────┬──────────┐
│ user_id │  status  │
├─────────┼──────────┤
│   10    │  online  │
│   20    │  busy    │
│   30    │  offline │
└─────────┴──────────┘
```

**Propósito**: Saber se usuário está online/busy/offline

### Fluxo Normal (Funcionando)

```
1. User muda status no frontend
   ↓
2. API: AccountUser.update!(availability: 'busy')
   ↓
3. Callback: after_save :update_presence_in_redis
   ↓
4. Redis atualizado:
   - HSET "ONLINE_STATUS::1" "10" "busy"
   ↓
5. WebSocket broadcast: presence.update
   ↓
6. Frontend recebe e atualiza UI
   ↓
7. ✅ UI mostra "busy" corretamente
```

### Fluxo Quebrado (update_all)

```
1. Admin roda: AccountUser.update_all(availability: 'online')
   ↓
2. PostgreSQL: availability = 'online' ✅
   ↓
3. Callbacks IGNORADOS ❌
   ↓
4. Redis: Ainda tem valor antigo "offline" ❌
   ↓
5. WebSocket broadcast: presence.update
   ↓
6. Pega do Redis: "offline" (stale) ❌
   ↓
7. ❌ UI mostra "offline" (errado)
```

---

## Por que Redis "atua" mesmo com auto_offline=false?

### Expectativa Errada

Você pode pensar: "Se `auto_offline = false`, o sistema deveria ignorar Redis e usar só o banco de dados, certo?"

**ERRADO!** Veja por quê:

### Onde auto_offline=false funciona

```ruby
# app/models/concerns/availability_statusable.rb:23-29
def user_availability_status
  return availability unless auto_offline  # ← Retorna DB direto se false

  # auto_offline=true: Usa Redis + heartbeat
  online_presence? ? (redis_status || availability) : 'offline'
end
```

Esse método é chamado em:
- ✅ API endpoints (`/api/v1/profile`)
- ✅ Jbuilder views (`_agent.json.jbuilder`)

### Onde auto_offline=false NÃO funciona

```ruby
# app/channels/room_channel.rb:19-25
def broadcast_presence
  return if @current_account.blank?

  # ⚠️ SEMPRE usa Redis, independente de auto_offline!
  data = {
    account_id: @current_account.id,
    users: ::OnlineStatusTracker.get_available_users(@current_account.id)
  }
  ActionCable.server.broadcast(pubsub_token, { event: 'presence.update', data: data })
end
```

E dentro de `get_available_users`:

```ruby
# lib/online_status_tracker.rb:69-76
def self.get_available_user_ids(account_id)
  # Usuários com heartbeat recente
  user_ids = Redis::Alfred.zrangebyscore(presence_key(...), range_start, '+inf')

  # ⚠️ ADICIONA usuários com auto_offline=false (SEMPRE na lista)
  user_ids += account.account_users.where(auto_offline: false)
                    .map(&:user_id).map(&:to_s)

  user_ids.uniq
end

# lib/online_status_tracker.rb:54-61
def self.get_available_users(account_id)
  user_ids = get_available_user_ids(account_id)

  # ⚠️ BUSCA STATUS DO REDIS (mesmo com auto_offline=false!)
  user_availabilities = Redis::Alfred.hmget(status_key(account_id), user_ids)

  # Só usa DB como fallback se Redis retornar nil (não quando retorna valor stale)
  user_ids.map.with_index { |id, index|
    [id, (user_availabilities[index] || get_availability_from_db(account_id, id))]
  }.to_h
end
```

### Resumo da Inconsistência

| Contexto | auto_offline=false funciona? |
|----------|------------------------------|
| **API `/api/v1/profile`** | ✅ Sim (usa DB) |
| **Jbuilder `_agent.json`** | ✅ Sim (usa DB) |
| **WebSocket `presence.update`** | ❌ Não (usa Redis) |

**Problema**: O WebSocket broadcast (usado para atualizar UI em tempo real) **SEMPRE lê do Redis**, mesmo com `auto_offline=false`.

---

## Diagnóstico

### 1. Verificar Status no Banco de Dados

```ruby
# Rails Console
user = User.find_by(email: 'agente@example.com')
au = user.account_users.find_by(account_id: 1)

puts "=== Database ==="
puts "auto_offline: #{au.auto_offline}"
puts "availability: #{au.availability}"
```

### 2. Verificar Status no Redis

```ruby
puts "\n=== Redis ==="
redis_status = OnlineStatusTracker.get_status(au.account_id, user.id)
puts "cached status: #{redis_status || 'NOT SET'}"
```

### 3. Verificar Status Final Computado

```ruby
puts "\n=== Final Computed Status ==="
puts "user_availability_status: #{au.user_availability_status}"
```

### 4. Comparar TODOS os agentes

```ruby
account_id = 1

puts "USER_ID | EMAIL | DB_AVAILABILITY | AUTO_OFFLINE | REDIS_STATUS | MATCH?"
puts "-" * 100

AccountUser.where(account_id: account_id).includes(:user).find_each do |au|
  user = au.user
  db_status = au.availability
  redis_status = OnlineStatusTracker.get_status(au.account_id, user.id)
  match = (db_status == redis_status) ? "✅" : "❌"

  puts "#{user.id} | #{user.email} | #{db_status} | #{au.auto_offline} | #{redis_status || 'NOT_SET'} | #{match}"
end
```

---

## Solução

### Opção A: Conservador (ZERO downtime) ⭐ RECOMENDADO

Use quando:
- Ambiente de produção
- Quer garantia de 100% sincronização
- Pode esperar 30-60 segundos

```ruby
# Rails Console

# 1. Sincronizar TUDO (online E offline) baseado no DB atual
AccountUser.where(account_id: 1).find_each do |au|
  OnlineStatusTracker.set_status(au.account_id, au.user_id, au.availability)
end

# 2. Verificar sincronização (opcional, mas recomendado)
mismatches = []
AccountUser.where(account_id: 1).each do |au|
  db = au.availability
  redis = OnlineStatusTracker.get_status(au.account_id, au.user_id)
  mismatches << au.user_id if db != redis
end
puts mismatches.any? ? "❌ Mismatches: #{mismatches}" : "✅ All synced!"

# 3. Voltar para auto_offline = true (com callbacks)
AccountUser.where(account_id: 1).find_each do |au|
  au.update!(auto_offline: true)
end
```

**Resultado esperado**:
```
✅ All synced!
```

**Tempo**: ~30-60 segundos (33 operadores)
**Risco**: Mínimo
**Garantia**: Redis e DB 100% sincronizados

---

### Opção B: Rápido (segundos de inconsistência possível)

Use quando:
- Muitos usuários (100+)
- Precisa ser rápido
- Pode tolerar breve janela de inconsistência

```ruby
# Rails Console

# 1. Sincronizar TUDO
AccountUser.where(account_id: 1).find_each do |au|
  OnlineStatusTracker.set_status(au.account_id, au.user_id, au.availability)
end

# 2. Voltar para auto_offline = true (bulk, rápido)
AccountUser.where(account_id: 1).update_all(auto_offline: true)

# 3. Re-sync imediatamente (caso alguém mudou status entre step 1 e 2)
AccountUser.where(account_id: 1).find_each do |au|
  OnlineStatusTracker.set_status(au.account_id, au.user_id, au.availability)
end
```

**Tempo**: ~10-20 segundos
**Risco**: Baixo (pequena janela entre step 1 e 2)
**Garantia**: Re-sync final garante consistência

---

### Opção C: Usuários Específicos

Use quando:
- Apenas alguns usuários afetados (< 10)
- Sabe os emails específicos
- Quer correção cirúrgica

```ruby
# Rails Console

user_emails = [
  'agente1@example.com',
  'agente2@example.com',
  'agente3@example.com'
]

user_emails.each do |email|
  user = User.find_by(email: email)
  next unless user

  user.account_users.where(account_id: 1).each do |au|
    OnlineStatusTracker.set_status(au.account_id, user.id, au.availability)
    puts "✅ #{user.name} - Status '#{au.availability}' atualizado no Redis"
  end
end
```

---

### Opção D: Limpar Redis Completamente (NÃO RECOMENDADO)

⚠️ **Use apenas em casos extremos ou ambientes não-produção**

```ruby
# Rails Console
account_id = 1

# Deletar chaves Redis
Redis::Alfred.del("ONLINE_PRESENCE::#{account_id}::USERS")
Redis::Alfred.del("ONLINE_STATUS::#{account_id}")

puts "⚠️  Redis cleared for account #{account_id}"
puts "Agents will show offline until next heartbeat (20s) or manual sync"

# Imediatamente sync do DB
AccountUser.where(account_id: account_id).find_each do |au|
  OnlineStatusTracker.set_status(au.account_id, au.user_id, au.availability)
end
puts "✅ Redis resynced from database"
```

**Efeitos colaterais**:
- TODOS agentes aparecem offline por ~20 segundos
- Heartbeats ativos repopulam automaticamente
- Usuários deslogados precisam sync manual

---

## Prevenção Futura

### 1. Use Métodos que Disparam Callbacks

```ruby
# ❌ EVITE (bypassa callbacks)
AccountUser.update_all(availability: 'online')
AccountUser.where(...).update_columns(campo: valor)

# ✅ PREFIRA (dispara callbacks)
AccountUser.where(...).find_each do |au|
  au.update!(availability: 'online')
end
```

### 2. Se Usar update_all, Sync Imediatamente

```ruby
# Rápido: update_all
AccountUser.where(account_id: 1).update_all(auto_offline: false)

# Seguro: sync Redis logo depois
AccountUser.where(account_id: 1).find_each do |au|
  OnlineStatusTracker.set_status(au.account_id, au.user_id, au.availability)
end
```

### 3. Crie Rake Task para Operações Recorrentes

```ruby
# lib/tasks/agent_management.rake
namespace :chatwoot do
  desc 'Safely update auto_offline and sync Redis'
  task :set_auto_offline, [:account_id, :value] => :environment do |_t, args|
    account_id = args[:account_id].to_i
    value = args[:value] == 'true'

    puts "Setting auto_offline=#{value} for account #{account_id}..."

    # Update com callbacks (mais lento mas seguro)
    count = 0
    AccountUser.where(account_id: account_id).find_each do |au|
      au.update!(auto_offline: value)
      count += 1
    end

    puts "✅ Updated #{count} agents"

    # Verificar sincronização
    mismatches = []
    AccountUser.where(account_id: account_id).each do |au|
      db = au.availability
      redis = OnlineStatusTracker.get_status(au.account_id, au.user_id)
      mismatches << au.user_id if db != redis
    end

    if mismatches.any?
      puts "⚠️  Mismatches found: #{mismatches.join(', ')}"
      puts "Running manual sync..."

      AccountUser.where(account_id: account_id, user_id: mismatches).find_each do |au|
        OnlineStatusTracker.set_status(au.account_id, au.user_id, au.availability)
      end

      puts "✅ Manual sync completed"
    else
      puts "✅ All agents synced correctly"
    end
  end

  desc 'Sync Redis with database for specific account'
  task :sync_redis_presence, [:account_id] => :environment do |_t, args|
    account_id = args[:account_id].to_i

    puts "Syncing Redis presence for account #{account_id}..."

    AccountUser.where(account_id: account_id).find_each do |au|
      OnlineStatusTracker.set_status(au.account_id, au.user_id, au.availability)
    end

    puts "✅ Sync completed"
  end
end
```

**Uso**:
```bash
# Desabilitar auto_offline com segurança
bundle exec rake chatwoot:set_auto_offline[1,false]

# Habilitar auto_offline com segurança
bundle exec rake chatwoot:set_auto_offline[1,true]

# Sync manual Redis
bundle exec rake chatwoot:sync_redis_presence[1]
```

---

## Comandos Redis Úteis (Debug)

### Conectar no Redis

```bash
# Docker/Portainer
docker exec -it <redis_container> redis-cli

# Ou se Redis local
redis-cli
```

### Ver Dados de Presença

```redis
# Ver todos usuários com presença ativa (account_id = 1)
ZRANGE "ONLINE_PRESENCE::1::USERS" 0 -1 WITHSCORES

# Output exemplo:
# 1) "10"           ← user_id
# 2) "1737489610"   ← timestamp
# 3) "20"
# 4) "1737489605"
```

### Ver Status dos Usuários

```redis
# Ver todos os status (account_id = 1)
HGETALL "ONLINE_STATUS::1"

# Output exemplo:
# 1) "10"      ← user_id
# 2) "online"  ← status
# 3) "20"
# 4) "busy"
# 5) "30"
# 6) "offline"
```

### Verificar Usuário Específico

```redis
# Verificar presença (retorna timestamp ou nil)
ZSCORE "ONLINE_PRESENCE::1::USERS" 10

# Verificar status (retorna online/busy/offline ou nil)
HGET "ONLINE_STATUS::1" "10"
```

### Limpar Dados

```redis
# Deletar presença de uma conta
DEL "ONLINE_PRESENCE::1::USERS"

# Deletar status de uma conta
DEL "ONLINE_STATUS::1"

# Deletar usuário específico
ZREM "ONLINE_PRESENCE::1::USERS" 10
HDEL "ONLINE_STATUS::1" "10"
```

---

## FAQ

### P: Por que não usar apenas o banco de dados?

**R**: Performance. Redis em memória é ~100x mais rápido que PostgreSQL. O WebSocket `presence.update` é enviado a cada 20 segundos para TODOS os usuários conectados. Fazer query no PostgreSQL toda vez seria lento e causaria sobrecarga no banco.

### P: Por que Redis não é atualizado automaticamente quando uso update_all?

**R**: `update_all()` é um atalho SQL que bypassa completamente o ActiveRecord. Não instancia objetos, não valida, não dispara callbacks. É rápido mas "cego" para lógica Ruby.

### P: Posso desabilitar auto_offline permanentemente?

**R**: Sim, mas não é recomendado. O `auto_offline=true` é o comportamento padrão do Chatwoot por uma razão: agentes que fecham o navegador sem deslogar aparecem online indefinidamente se `auto_offline=false`. Isso confunde usuários finais.

### P: O que acontece se eu reiniciar o Redis?

**R**:
1. Todos os dados em memória são perdidos
2. Todos agentes aparecem offline temporariamente
3. Após 20 segundos, heartbeats repopulam a presença
4. Usuários deslogados precisam sync manual ou próximo login

### P: Posso usar isso em produção com tráfego ativo?

**R**: Sim! A **Opção A (Conservador)** é segura para produção. Usa `find_each` que processa em batches e `update!` que dispara callbacks corretamente. Zero downtime, zero perda de dados.

### P: Quanto tempo leva para sincronizar 100 agentes?

**R**:
- **Opção A** (com callbacks): ~2-3 minutos
- **Opção B** (update_all + resync): ~30-60 segundos
- **Opção C** (usuários específicos): ~1-5 segundos

---

## Arquivos Relacionados

### Backend

- `app/models/account_user.rb:41` - Callback `after_save :update_presence_in_redis`
- `app/models/account_user.rb:79-81` - Método `update_presence_in_redis`
- `app/models/concerns/availability_statusable.rb:23-29` - Lógica `user_availability_status`
- `lib/online_status_tracker.rb` - Service de gerenciamento Redis
- `app/channels/room_channel.rb:19-25` - WebSocket broadcast

### Frontend

- `app/javascript/shared/helpers/BaseActionCableConnector.js` - Heartbeat (20s)
- `app/javascript/dashboard/helper/actionCable.js` - Event handler `presence.update`

### Documentação

- `.claude/skills/chatwoot-redis-presence-sync.md` - Skill para Claude Code
- `.claude/skills/chatwoot-agent-presence.md` - Skill sobre sistema de presença
- `docs/md/auto_offline.md` - Guia completo sobre auto_offline

---

## Caso Real: Resolução Bem-Sucedida

### Situação Inicial

```ruby
# Admin rodou em produção:
AccountUser.where(account_id: 1).update_all(auto_offline: false)

# Resultado:
# - Banco: auto_offline = false ✅
# - Redis: Dados stale (status antigos) ❌
# - UI: Agentes aparecem offline ❌
```

### Solução Aplicada

```ruby
# 1. Sync completo
AccountUser.where(account_id: 1).find_each do |au|
  OnlineStatusTracker.set_status(au.account_id, au.user_id, au.availability)
end

# 2. Verificação
mismatches = []
AccountUser.where(account_id: 1).each do |au|
  db = au.availability
  redis = OnlineStatusTracker.get_status(au.account_id, au.user_id)
  mismatches << au.user_id if db != redis
end
puts mismatches.any? ? "❌ Mismatches" : "✅ All synced!"
# Output: ✅ All synced!

# 3. Restaurar comportamento padrão
AccountUser.where(account_id: 1).find_each do |au|
  au.update!(auto_offline: true)
end
```

### Resultado Final

```ruby
# - Banco: auto_offline = true ✅
# - Redis: Sincronizado com banco ✅
# - UI: Status correto em tempo real ✅
# - Callbacks: Funcionando normalmente ✅
```

**Tempo total**: ~45 segundos
**Downtime**: Zero
**Agentes afetados negativamente**: Zero

---

## Conclusão

O problema de Redis desatualizado acontece quando:

1. Usamos métodos que bypassam callbacks (`update_all`, `update_columns`)
2. O callback `after_save :update_presence_in_redis` não dispara
3. WebSocket `presence.update` lê do Redis (sempre, mesmo com `auto_offline=false`)
4. UI mostra dados stale do cache

**Solução**: Sincronizar manualmente ou usar métodos que disparam callbacks.

**Prevenção**: Criar rake tasks que fazem update + sync automaticamente.

**Best Practice**: Use `auto_offline=true` (padrão do Chatwoot) para melhor UX.
