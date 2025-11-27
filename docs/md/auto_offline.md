# Auto Offline - Chatwoot

## Visão Geral

O **auto_offline** é uma funcionalidade do Chatwoot que gerencia automaticamente o status de disponibilidade dos agentes, marcando-os como offline quando eles param de enviar sinais de presença (heartbeat).

## Conceito

- **Campo**: `auto_offline` (booleano) na tabela `account_users`
- **Padrão**: `true`
- **Localização**: [app/models/account_user.rb:7](../app/models/account_user.rb#L7)

### Comportamento

| auto_offline | Comportamento |
|--------------|---------------|
| `true` (padrão) | Agente é automaticamente marcado como **offline** quando para de enviar heartbeat por mais de 20 segundos |
| `false` | Agente **nunca** é marcado como offline automaticamente. Status determinado apenas pelo campo `availability` |

## Arquitetura

### 1. Sistema de Presença (Heartbeat)

#### Frontend
- **Intervalo**: A cada **20 segundos**
- **Arquivo**: [app/javascript/shared/helpers/BaseActionCableConnector.js](../app/javascript/shared/helpers/BaseActionCableConnector.js)
- **Ação**: Envia sinal via WebSocket (`update_presence`)

```javascript
// BaseActionCableConnector.js:21-42
PRESENCE_INTERVAL = 20000ms  // 20 segundos
```

#### Backend
- **Serviço**: `OnlineStatusTracker`
- **Arquivo**: [lib/online_status_tracker.rb](../lib/online_status_tracker.rb)
- **Storage**: Redis Sorted Sets
- **Duração**: Variável de ambiente `PRESENCE_DURATION` (padrão: 20 segundos)

### 2. Armazenamento Redis

```
ONLINE_PRESENCE::{account_id}::USERS
  → Sorted Set: user_id (member) + timestamp (score)

ONLINE_STATUS::{account_id}
  → Hash: user_id → availability (online/busy/offline)
```

**Arquivo**: [lib/redis/redis_keys.rb:19-23](../lib/redis/redis_keys.rb#L19-L23)

### 3. Lógica de Disponibilidade

**Arquivo**: [app/models/concerns/availability_statusable.rb:23-29](../app/models/concerns/availability_statusable.rb#L23-L29)

```ruby
def user_availability_status
  if auto_offline == false
    # Retorna sempre o campo 'availability'
    # Agente NUNCA é marcado offline automaticamente
    return availability
  else
    # auto_offline == true (padrão)
    if presenca_valida_no_redis?
      return redis_status
    else
      return 'offline'  # Marca offline se presença expirou
    end
  end
end
```

## Fluxo de Detecção

### Cenário 1: Agente Fecha o Navegador

1. Conexão WebSocket é encerrada
2. Callback `disconnected()` é acionado no frontend
3. Heartbeat para de ser enviado
4. **Após 20 segundos**: presença expira no Redis
5. Próximo broadcast de presença não inclui o agente
6. Frontend recebe `presence.update` event
7. **Agente marcado como OFFLINE** na UI

### Cenário 2: Agente Faz Logout

1. Clica em "Logout" no menu do perfil
2. Request `DELETE /auth/sign_out`
3. Cookies e LocalStorage são limpos
4. WebSocket é fechado
5. Mesmo fluxo do **Cenário 1**

**Arquivo**: [app/javascript/dashboard/store/utils/api.js:79-88](../app/javascript/dashboard/store/utils/api.js#L79-L88)

### Cenário 3: Interrupção de Rede

1. Conexão cai inesperadamente
2. Timer de reconexão inicia (verifica a cada 1 segundo)
3. **Se reconectar em < 20s**: presença mantida → continua **online**
4. **Se não reconectar em 20s+**: presença expira → marcado **offline**

**Arquivo**: [app/javascript/shared/helpers/BaseActionCableConnector.js:26-29](../app/javascript/shared/helpers/BaseActionCableConnector.js#L26-L29)

### Cenário 4: auto_offline = false

1. Agente desconecta/logout
2. Presença expira no Redis
3. **MAS** agente permanece na lista de disponíveis
4. Status determinado **apenas** pelo campo `availability`
5. Agente pode receber conversas mesmo offline

**Arquivo**: [lib/online_status_tracker.rb:74](../lib/online_status_tracker.rb#L74)

```ruby
# Inclui usuários com auto_offline: false mesmo sem presença
def get_available_user_ids(account_id, ids = nil)
  # ...
  AccountUser.where(account_id: account_id, auto_offline: false, user_id: ids)
             .pluck(:user_id)
end
```

## Componentes Principais

### Backend

| Arquivo | Responsabilidade |
|---------|------------------|
| [lib/online_status_tracker.rb](../lib/online_status_tracker.rb) | Serviço principal de rastreamento de presença |
| [app/channels/room_channel.rb](../app/channels/room_channel.rb) | WebSocket que recebe heartbeats e faz broadcast |
| [app/models/concerns/availability_statusable.rb](../app/models/concerns/availability_statusable.rb) | Lógica de determinação de status |
| [app/models/account_user.rb](../app/models/account_user.rb) | Model com campo `auto_offline` |
| [app/controllers/api/v1/profiles_controller.rb](../app/controllers/api/v1/profiles_controller.rb) | Endpoints de API |

### Frontend

| Arquivo | Responsabilidade |
|---------|------------------|
| [BaseActionCableConnector.js](../app/javascript/shared/helpers/BaseActionCableConnector.js) | Envia heartbeat a cada 20s |
| [actionCable.js](../app/javascript/dashboard/helper/actionCable.js) | Recebe eventos `presence.update` |
| [auth.js](../app/javascript/dashboard/store/modules/auth.js) | Vuex store - gerencia estado do usuário atual |
| [agents.js](../app/javascript/dashboard/store/modules/agents.js) | Vuex store - atualiza presença de todos agentes |
| [SidebarProfileMenuStatus.vue](../app/javascript/dashboard/components-next/sidebar/SidebarProfileMenuStatus.vue) | UI - Toggle e dropdown de status |

## API Endpoints

### 1. Atualizar Disponibilidade

```http
POST /api/v1/profile/availability
Content-Type: application/json

{
  "availability": "online" | "offline" | "busy"
}
```

**Arquivo**: [app/controllers/api/v1/profiles_controller.rb:27-29](../app/controllers/api/v1/profiles_controller.rb#L27-L29)

### 2. Atualizar Auto Offline

```http
POST /api/v1/profile/auto_offline
Content-Type: application/json

{
  "auto_offline": true | false
}
```

**Arquivo**: [app/controllers/api/v1/profiles_controller.rb:23-25](../app/controllers/api/v1/profiles_controller.rb#L23-L25)

## Configuração no Banco de Dados

### Estrutura da Tabela

```ruby
# Schema: account_users
t.boolean "auto_offline", default: true, null: false
t.integer "availability", default: 0, null: false  # 0=online, 1=offline, 2=busy
```

**Migration**: [db/migrate/20230426130150_init_schema.rb:26](../db/migrate/20230426130150_init_schema.rb#L26)

### Atualizar auto_offline via SQL

```sql
-- Atualizar todos os agentes
UPDATE account_users SET auto_offline = true;

-- Atualizar por conta específica
UPDATE account_users SET auto_offline = true WHERE account_id = 1;

-- Verificar distribuição
SELECT auto_offline, COUNT(*)
FROM account_users
GROUP BY auto_offline;

-- Ver detalhes por conta
SELECT
  account_id,
  COUNT(*) as total_agentes,
  SUM(CASE WHEN auto_offline = true THEN 1 ELSE 0 END) as com_auto_offline,
  SUM(CASE WHEN auto_offline = false THEN 1 ELSE 0 END) as sem_auto_offline
FROM account_users
GROUP BY account_id;
```

### Atualizar via Rails Console

```ruby
# Acessar console
bundle exec rails console
# ou em produção:
RAILS_ENV=production bundle exec rails console

# Atualizar todos
AccountUser.update_all(auto_offline: true)

# Atualizar por conta
AccountUser.where(account_id: 1).update_all(auto_offline: true)

# Atualizar agente específico
user = User.find_by(email: 'agente@exemplo.com')
AccountUser.where(user_id: user.id).update_all(auto_offline: true)

# Verificar quantos estão com auto_offline = false
AccountUser.where(auto_offline: false).count

# Ver distribuição
AccountUser.group(:auto_offline).count
```

### Migration para Atualização em Massa

```ruby
# db/migrate/YYYYMMDDHHMMSS_set_auto_offline_to_true.rb
class SetAutoOfflineToTrue < ActiveRecord::Migration[7.0]
  def up
    AccountUser.where(auto_offline: false).update_all(auto_offline: true)
    Rails.logger.info "Updated #{AccountUser.where(auto_offline: true).count} account_users"
  end

  def down
    # Rollback opcional
  end
end
```

Executar:
```bash
bundle exec rails db:migrate
# ou em produção:
RAILS_ENV=production bundle exec rails db:migrate
```

## Variáveis de Ambiente

```bash
# Duração da presença (em segundos)
PRESENCE_DURATION=20  # Padrão: 20 segundos
```

**Arquivo**: [lib/online_status_tracker.rb:3](../lib/online_status_tracker.rb#L3)

## Interface do Usuário

### Localização do Toggle

1. Menu do perfil (canto inferior esquerdo)
2. Seção "Availability Status"
3. Toggle "Auto Offline"

**Arquivo**: [SidebarProfileMenuStatus.vue:118-126](../app/javascript/dashboard/components-next/sidebar/SidebarProfileMenuStatus.vue#L118-L126)

### Tooltip

> "When enabled, your status will automatically change to offline when you close the app or browser."

## Casos de Uso

### Quando usar auto_offline = true (Padrão)

✅ **Recomendado para**:
- Agentes que trabalham em horários fixos
- Ambientes onde apenas agentes ativos devem receber conversas
- Melhor experiência do cliente (evita timeout esperando agente offline)

### Quando usar auto_offline = false

✅ **Útil para**:
- Agentes que querem receber conversas mesmo após fechar o navegador
- Notificações push/email para conversas atribuídas
- Administradores que precisam estar sempre disponíveis
- Ambientes com internet instável

## Testes

**Arquivo**: [spec/lib/online_status_tracker_spec.rb](../spec/lib/online_status_tracker_spec.rb)

```ruby
# Linha 20-22: Testa que agentes com auto_offline: false
# são retornados em get_available_users mesmo sem presença

# Linha 52-55: Testa que registros de presença expirados
# são removidos após PRESENCE_DURATION
```

## Debugging

### Verificar Presença no Redis

```bash
# Conectar ao Redis
redis-cli

# Ver presença de usuários de uma conta
ZRANGE "ONLINE_PRESENCE::1::USERS" 0 -1 WITHSCORES

# Ver status de disponibilidade
HGETALL "ONLINE_STATUS::1"

# Limpar presença (forçar re-sync)
DEL "ONLINE_PRESENCE::1::USERS"
DEL "ONLINE_STATUS::1"
```

### Verificar Logs

```ruby
# Rails console
Rails.logger.info OnlineStatusTracker.get_available_users(account_id)
Rails.logger.info OnlineStatusTracker.get_presence(account_id, user_id)
```

### Simular Desconexão

1. Abrir DevTools → Network tab
2. Throttling → Offline
3. Aguardar 20 segundos
4. Verificar se agente foi marcado offline

## Troubleshooting

### 🔴 Agente alternando entre online/offline (piscando)

**Sintoma**: Agente que está deslogado aparece alternando constantemente entre online e offline na lista de agentes.

**Causa raiz**:
1. **Sessões antigas ainda ativas** - Conexões WebSocket antigas continuam enviando heartbeat
2. **pubsub_token não foi invalidado** - Token do WebSocket só é regenerado quando muda senha (ver [pubsubable.rb:17-18](../app/models/concerns/pubsubable.rb#L17-L18))
3. **Redis recebe presença de conexões fantasmas** - Múltiplas sessões enviando dados conflitantes

**Solução imediata** (via Rails Console):

```ruby
# 1. Encontrar o usuário
user = User.find_by(email: 'usuario@exemplo.com')
# ou por ID: user = User.find(123)

# 2. Regenerar o pubsub_token (invalida conexões antigas)
user.regenerate_pubsub_token
user.save!

# 3. Limpar Redis e forçar offline
user.account_users.each do |au|
  OnlineStatusTracker.set_status(au.account_id, user.id, 'offline')
end

# 4. Verificar
puts "Novo pubsub_token: #{user.pubsub_token}"
```

**Solução via Rake Task**:

```bash
# Limpar agente específico
bundle exec rake chatwoot:cleanup_agent_presence USER_EMAIL=usuario@exemplo.com

# Limpar todos agentes problemáticos (auto_offline=true e availability=online)
bundle exec rake chatwoot:cleanup_agent_presence

# Emergência: forçar TODOS offline no Redis
bundle exec rake chatwoot:force_all_agents_offline
```

**Rake Task criado**: [lib/tasks/cleanup_agent_presence.rake](../lib/tasks/cleanup_agent_presence.rake)

**Verificação pós-correção**:
```ruby
# Ver se ainda tem presença no Redis
OnlineStatusTracker.get_presence(account_id, user.id)
# => deve retornar nil ou expirado

# Ver status no Redis
OnlineStatusTracker.get_status(account_id, user.id)
# => deve retornar "offline"
```

### Agente não fica offline após logout

**Possíveis causas**:
1. `auto_offline = false` no banco
2. Redis não está funcionando
3. Presença sendo atualizada por outra sessão (múltiplas abas)
4. Sessão antiga ainda conectada (ver problema acima ⬆️)

**Solução**:
```ruby
# Verificar configuração
AccountUser.find_by(user_id: X).auto_offline

# Verificar Redis
OnlineStatusTracker.get_presence(account_id, user_id)

# Se persistir, regenerar token (ver seção acima)
user.regenerate_pubsub_token
user.save!
```

### Agente fica offline durante navegação

**Possíveis causas**:
1. Heartbeat não está sendo enviado (erro no WebSocket)
2. PRESENCE_DURATION muito curto
3. Problemas de rede intermitentes

**Solução**:
- Verificar console do navegador para erros WebSocket
- Aumentar `PRESENCE_DURATION` se necessário
- Verificar estabilidade da conexão

### Multiplas abas abertas

**Comportamento**:
- Cada aba envia seu próprio heartbeat
- Agente fica online enquanto **pelo menos uma aba** estiver ativa
- Ao fechar todas as abas, 20 segundos depois fica offline

### Limpar todas as sessões de um usuário

**Forçar logout completo**:
```ruby
user = User.find_by(email: 'usuario@exemplo.com')

# Limpar tokens do Devise (sessões web)
user.tokens = {}
user.save!

# Regenerar pubsub_token (WebSocket)
user.regenerate_pubsub_token
user.save!

# Limpar Redis
user.account_users.each do |au|
  OnlineStatusTracker.set_status(au.account_id, user.id, 'offline')
end
```

## Referências

- [Online Status Tracker Service](../lib/online_status_tracker.rb)
- [Availability Statusable Concern](../app/models/concerns/availability_statusable.rb)
- [Room Channel (WebSocket)](../app/channels/room_channel.rb)
- [Base Action Cable Connector](../app/javascript/shared/helpers/BaseActionCableConnector.js)
- [Profile Menu Status Component](../app/javascript/dashboard/components-next/sidebar/SidebarProfileMenuStatus.vue)

---

**Última atualização**: 2025-01-18
**Versão do Chatwoot**: 4.7.0+
