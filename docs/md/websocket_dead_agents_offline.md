# WebSocket Dead - Agents Stuck Offline

## Problema

Agentes aparecem como "offline" na interface mesmo estando logados e ativos no sistema.

### Sintomas

- ✅ Agente está logado no navegador
- ✅ Agente está trabalhando normalmente (respondendo mensagens)
- ❌ Status aparece como "offline" para outros usuários
- ❌ Status oscila entre "online" e "offline" aleatoriamente
- ❌ Hard refresh (CTRL+SHIFT+R) não resolve
- ✅ Logout/login temporariamente resolve, mas problema retorna

---

## Causa Raiz

### WebSocket (ActionCable) Desconectado

O Chatwoot usa **WebSocket** (via ActionCable) para manter conexão em tempo real com o servidor. Essa conexão envia um **heartbeat a cada 20 segundos**.

Quando o WebSocket desconecta e **não reconecta automaticamente**:
1. ❌ Heartbeat para de ser enviado
2. ⏱️ Após 20 segundos sem heartbeat → Sistema marca agente como "offline"
3. 🔴 Agente fica preso no estado "offline" mesmo estando ativo

### Por Que o WebSocket Morre?

#### 1. **Browser Suspende a Aba** (CAUSA MAIS COMUM) 🔴

Navegadores modernos (Chrome, Edge, Firefox) economizam bateria/memória suspendendo abas inativas:

```
User abre Chatwoot → WebSocket conecta ✅
  ↓
User troca de aba (trabalha em outro lugar)
  ↓
Após 5-10 minutos → Browser suspende aba do Chatwoot
  ↓
JavaScript pausado → Heartbeat para de enviar ❌
  ↓
Após 20s sem heartbeat → Sistema marca offline ❌
  ↓
User volta para aba do Chatwoot
  ↓
JavaScript resume MAS WebSocket NÃO reconecta ❌
  ↓
Agente fica offline permanentemente 🔴
```

**Gatilhos comuns**:
- Aba inativa por 5-10+ minutos
- Laptop em modo "economia de bateria"
- Muitas abas abertas (browser prioriza memória)
- Browser configurado para "economia de recursos"

---

#### 2. **Rede Instável**

```
WebSocket conectado ✅
  ↓
Conexão de rede flutua (WiFi instável, VPN)
  ↓
WebSocket desconecta ❌
  ↓
Lógica de reconexão tenta reconectar
  ↓
Reconexão FALHA (token inválido, timeout, etc.) ❌
  ↓
Heartbeat nunca mais enviado 🔴
```

---

#### 3. **Proxy/Load Balancer Dropando WebSocket**

```
Client ←→ Nginx/Proxy ←→ Rails Server
           ↑
           WebSocket timeout configurado muito curto
           Conexão dropada após X minutos
```

---

#### 4. **pubsub_token Inválido/Expirado**

```
User fez login há dias/semanas
  ↓
Token foi regenerado no servidor (admin resetou senhas, etc.)
  ↓
WebSocket tenta autenticar com token antigo ❌
  ↓
Autenticação falha → Conexão rejeitada 🔴
```

---

## Arquitetura do Sistema de Presença

### Como o Heartbeat Funciona

```
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND (Browser)                       │
│                                                             │
│  BaseActionCableConnector.js                                │
│  ┌────────────────────────────────────┐                     │
│  │ setInterval(() => {                │                     │
│  │   subscription.updatePresence()    │ ← A cada 20s        │
│  │ }, 20000)                          │                     │
│  └────────────────────────────────────┘                     │
│                      ↓ WebSocket                            │
└─────────────────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                    BACKEND (Rails)                          │
│                                                             │
│  RoomChannel#update_presence                                │
│  ┌────────────────────────────────────┐                     │
│  │ OnlineStatusTracker.update_presence│                     │
│  │   ↓                                │                     │
│  │ ZADD ONLINE_PRESENCE::1::USERS     │ ← Atualiza Redis    │
│  │      user_id, current_timestamp    │                     │
│  └────────────────────────────────────┘                     │
└─────────────────────────────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                      REDIS                                  │
│                                                             │
│  ONLINE_PRESENCE::1::USERS (Sorted Set)                     │
│  ┌─────────┬────────────┐                                   │
│  │ user_id │ timestamp  │                                   │
│  ├─────────┼────────────┤                                   │
│  │   10    │ 1737489600 │ ← 5s atrás  ✅ VÁLIDO            │
│  │   20    │ 1737489550 │ ← 55s atrás ❌ EXPIRADO (> 20s)  │
│  └─────────┴────────────┘                                   │
└─────────────────────────────────────────────────────────────┘
```

### Verificação de Status

```ruby
# app/models/concerns/availability_statusable.rb:23-29
def user_availability_status
  return availability unless auto_offline  # Se auto_offline=false, usa DB

  # Se auto_offline=true (padrão):
  online_presence? ? (redis_status || availability) : 'offline'
  #       ↑
  #   Verifica se heartbeat < 20s
  #   Se NÃO → FORÇA 'offline' independente do DB
end
```

```ruby
# lib/online_status_tracker.rb:12-15
def self.get_presence(account_id, obj_type, obj_id)
  connected_time = Redis::Alfred.zscore(presence_key(account_id, obj_type), obj_id)

  # Retorna TRUE se heartbeat < 20s
  connected_time && connected_time > (Time.zone.now - PRESENCE_DURATION).to_i
end
```

**Lógica**:
1. Pega timestamp do último heartbeat do Redis
2. Compara com tempo atual
3. Se diferença > 20 segundos → `online_presence? = false`
4. Se `auto_offline=true` → **Força status 'offline'**

---

## Diagnóstico

### Passo 1: Identificar Agentes com WebSocket Morto

```ruby
# Rails Console
puts "Buscando agentes com WebSocket morto..."
dead_agents = []

AccountUser.where(account_id: 1).includes(:user).find_each do |au|
  user = au.user
  presence_score = Redis::Alfred.zscore("ONLINE_PRESENCE::#{au.account_id}::USERS", user.id)

  if presence_score
    seconds_ago = Time.now.to_i - presence_score.to_i

    # Heartbeat expirado = WebSocket morto
    if seconds_ago > 20
      dead_agents << user
      puts "⚠️  #{user.name} (#{user.email}) - Last heartbeat #{seconds_ago}s ago"
    end
  end
end

puts "\nTotal: #{dead_agents.count}"
```

**Output exemplo**:
```
⚠️  Alane (alanealmeida2022@gmail.com) - Last heartbeat 24s ago
⚠️  Cloves (cloves@caperbrasil.com.br) - Last heartbeat 52s ago
⚠️  Patricia.Barcelos (patybarcelos466@gmail.com) - Last heartbeat 457s ago

Total: 16
```

---

### Passo 2: Analisar Gravidade

```ruby
# Rails Console
critical = []   # < 2 min (acabou de cair)
high = []       # 2-30 min (provavelmente ainda logado)
medium = []     # 30 min - 2h (pode estar logado)
low = []        # > 2h (provavelmente deslogado)

dead_agents.each do |user|
  presence_score = Redis::Alfred.zscore("ONLINE_PRESENCE::1::USERS", user.id)
  seconds_ago = Time.now.to_i - presence_score.to_i
  minutes_ago = seconds_ago / 60

  case
  when seconds_ago < 120
    critical << "#{user.name} (#{seconds_ago}s ago)"
  when seconds_ago < 1800
    high << "#{user.name} (#{minutes_ago} min ago)"
  when seconds_ago < 7200
    medium << "#{user.name} (#{minutes_ago} min ago)"
  else
    low << "#{user.name} (#{minutes_ago} min ago)"
  end
end

puts "🔴 CRITICAL (< 2 min): #{critical.count}"
critical.each { |a| puts "  - #{a}" }

puts "\n🟠 HIGH (2-30 min): #{high.count}"
high.each { |a| puts "  - #{a}" }

puts "\n🟡 MEDIUM (30 min - 2h): #{medium.count}"
medium.each { |a| puts "  - #{a}" }

puts "\n⚪ LOW (> 2h): #{low.count}"
low.each { |a| puts "  - #{a}" }
```

---

### Passo 3: Monitorar Agente Específico em Tempo Real

```ruby
# Rails Console
user = User.find_by(email: 'alanealmeida2022@gmail.com')
au = user.account_users.find_by(account_id: 1)

puts "Monitorando #{user.name} por 60 segundos..."
puts "Time     | Heartbeat Age | Valid? | Computed Status"
puts "-" * 60

12.times do |i|
  sleep 5 if i > 0

  presence_score = Redis::Alfred.zscore("ONLINE_PRESENCE::#{au.account_id}::USERS", user.id)

  if presence_score
    seconds_ago = Time.now.to_i - presence_score.to_i
    valid = seconds_ago <= 20 ? "✅" : "❌"
    heartbeat_age = "#{seconds_ago}s"
  else
    valid = "❌"
    heartbeat_age = "NEVER"
  end

  computed = au.availability_status

  puts "#{Time.now.strftime('%H:%M:%S')} | #{heartbeat_age.ljust(13)} | #{valid}    | #{computed}"
end
```

**Output que confirma problema**:
```
14:46:43 | 18s           | ✅    | online
14:46:48 | 23s           | ❌    | offline  ← HEARTBEAT EXPIROU
14:46:53 | 28s           | ❌    | offline  ← NENHUM NOVO HEARTBEAT
14:46:58 | 33s           | ❌    | offline  ← WEBSOCKET MORTO
```

---

## Solução

### Solução Imediata: Regenerar Tokens e Forçar Reconexão

```ruby
# Rails Console

puts "=" * 80
puts "REGENERANDO TOKENS E LIMPANDO REDIS"
puts "=" * 80

dead_agents.each do |user|
  # 1. Regenerar pubsub_token (invalida WebSocket antigo)
  user.regenerate_pubsub_token
  user.save!

  # 2. Limpar presença do Redis
  au = user.account_users.find_by(account_id: 1)
  if au
    Redis::Alfred.zrem("ONLINE_PRESENCE::#{au.account_id}::USERS", user.id)
    OnlineStatusTracker.set_status(au.account_id, user.id, 'offline')
  end

  puts "✅ #{user.name} - Token regenerated, presence cleared"
end

puts "\n" + "=" * 80
puts "✅ CONCLUÍDO: #{dead_agents.count} agentes processados"
puts "=" * 80
puts "\n📢 PRÓXIMO PASSO: Avisar os agentes para fazer LOGOUT/LOGIN"
```

**O que isso faz**:
1. **Regenera `pubsub_token`** → Invalida todas as sessões WebSocket antigas
2. **Remove presença do Redis** → Limpa timestamp stale
3. **Força status offline** → Sincroniza estado correto

---

### Notificar Agentes Afetados

#### Para agentes CRÍTICOS (heartbeat < 2 min):

> 🚨 **URGENTE - [Nome], [Nome], [Nome]**
>
> Vocês estão com problema de conexão no sistema.
>
> **Façam AGORA**:
> 1. CTRL + SHIFT + R (recarregar página com cache limpo)
> 2. Se não resolver: Logout completo → Login novamente
>
> Façam isso nos próximos 2 minutos!

---

#### Para os outros:

> ⚠️ **Atenção time - Problema de conexão**
>
> Se vocês estão logados no Chatwoot, façam:
> 1. Logout completo
> 2. Login novamente
>
> Lista de quem precisa fazer isso:
> [Lista de nomes]
>
> Obrigado! 🙏

---

### Monitoramento Pós-Fix

Após 5 minutos da correção:

```ruby
# Rails Console
puts "#{Time.now.strftime('%H:%M:%S')} - Health Check Pós-Fix"
puts "=" * 80

healthy = 0
sick = 0
sick_agents = []

AccountUser.where(account_id: 1).includes(:user).find_each do |au|
  user = au.user
  presence_score = Redis::Alfred.zscore("ONLINE_PRESENCE::#{au.account_id}::USERS", user.id)

  if presence_score
    seconds_ago = Time.now.to_i - presence_score.to_i

    if seconds_ago <= 20
      healthy += 1
    else
      sick += 1
      sick_agents << "#{user.name} (#{seconds_ago}s ago)"
    end
  end
end

total_active = healthy + sick
puts "✅ Healthy WebSockets: #{healthy}"
puts "❌ Still dead: #{sick}"
puts "📊 Total active: #{total_active}"

if sick > 0
  puts "\n⚠️  Agents still with dead WebSocket:"
  sick_agents.each { |a| puts "  - #{a}" }
  puts "\n👉 These agents did NOT logout/login yet!"
end
```

---

## Prevenção

### 1. Aumentar PRESENCE_DURATION

Se WebSocket morre frequentemente devido a rede instável ou browser suspendendo abas:

```bash
# .env ou variáveis de ambiente
PRESENCE_DURATION=40  # Ao invés de 20 (padrão)
```

**Vantagens**:
- Tolera delays de rede
- Tolera browser suspendendo aba por curto período
- Menos falsos positivos

**Desvantagens**:
- Agente que realmente desconectou demora mais para aparecer offline (40s ao invés de 20s)

**Aplicar**:
1. Adicionar variável de ambiente
2. **Reiniciar servidor Rails** (necessário)

---

### 2. Configurar Proxy/Load Balancer para WebSocket

Se usar **Nginx, Apache, ou CloudFlare**:

```nginx
# nginx.conf
location /cable {
    proxy_pass http://rails_backend;
    proxy_http_version 1.1;

    # CRÍTICO para WebSocket
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;

    # Timeout longo para conexões persistentes
    proxy_read_timeout 3600s;   # 1 hora
    proxy_send_timeout 3600s;   # 1 hora
    proxy_connect_timeout 60s;
}
```

**Verificar**:
```bash
# Testar se WebSocket está funcionando
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: $(openssl rand -base64 16)" \
  https://seu-chatwoot.com/cable
```

**Deve retornar**: `HTTP/1.1 101 Switching Protocols`

---

### 3. Monitoramento Contínuo

Criar rake task para verificar periodicamente:

```ruby
# lib/tasks/websocket_health.rake
namespace :chatwoot do
  desc 'Check WebSocket health for all accounts'
  task websocket_health_check: :environment do
    Account.find_each do |account|
      dead_count = 0

      AccountUser.where(account_id: account.id).includes(:user).find_each do |au|
        presence_score = Redis::Alfred.zscore("ONLINE_PRESENCE::#{account.id}::USERS", au.user_id)

        if presence_score && (Time.now.to_i - presence_score.to_i > 60)
          # Heartbeat morto há mais de 1 minuto
          dead_count += 1
        end
      end

      if dead_count > 0
        puts "[#{Time.now}] Account #{account.id}: #{dead_count} agents with dead WebSocket"
        # Opcional: Enviar alerta (email, Slack, etc.)
      end
    end
  end
end
```

**Agendar com cron**:
```bash
# Executar a cada 5 minutos
*/5 * * * * cd /app && bundle exec rake chatwoot:websocket_health_check
```

---

### 4. Orientar Usuários

**Documentação interna para agentes**:

> ### ⚠️ Se você aparecer como "offline" mas está trabalhando:
>
> **Causa**: Problema de conexão do sistema.
>
> **Solução rápida**:
> 1. Apertar **CTRL + SHIFT + R** (recarregar página)
> 2. Se não resolver: **Logout** → **Login** novamente
>
> **Prevenção**:
> - Não deixe a aba do Chatwoot inativa por muito tempo
> - A cada 30 minutos, clique na aba do Chatwoot para "acordá-la"
> - Se usar múltiplos monitores, mantenha Chatwoot visível

---

## Rake Tasks Úteis

### Fix Dead WebSockets (Manual)

```ruby
# lib/tasks/fix_dead_websockets.rake
namespace :chatwoot do
  desc 'Fix dead WebSockets for an account'
  task :fix_dead_websockets, [:account_id] => :environment do |_t, args|
    account_id = args[:account_id].to_i

    puts "Searching for dead WebSockets in account #{account_id}..."

    dead_agents = []

    AccountUser.where(account_id: account_id).includes(:user).find_each do |au|
      user = au.user
      presence_score = Redis::Alfred.zscore("ONLINE_PRESENCE::#{account_id}::USERS", user.id)

      if presence_score && (Time.now.to_i - presence_score.to_i > 20)
        dead_agents << user

        # Regenerate token
        user.regenerate_pubsub_token
        user.save!

        # Clear Redis
        Redis::Alfred.zrem("ONLINE_PRESENCE::#{account_id}::USERS", user.id)
        OnlineStatusTracker.set_status(account_id, user.id, 'offline')

        puts "✅ #{user.name} (#{user.email})"
      end
    end

    puts "\n#{dead_agents.count} agents fixed. They must logout/login."
  end
end
```

**Uso**:
```bash
bundle exec rake chatwoot:fix_dead_websockets[1]
```

---

## Troubleshooting

### Q: Fiz logout/login mas continuo offline

**A**: Verifique se o navegador está de fato conectando ao WebSocket:

1. Abra **Console do Navegador** (F12)
2. Vá para aba **Network**
3. Filtre por **WS** (WebSocket)
4. Deve aparecer uma conexão para `/cable`
5. Status deve ser **101 Switching Protocols** (verde)

Se aparecer **erro 40x ou 50x**:
- pubsub_token inválido → Regenerar novamente
- Servidor não está aceitando WebSocket → Verificar configuração

---

### Q: WebSocket conecta mas heartbeat não é enviado

**A**: Verificar logs do navegador:

1. **Console** (F12)
2. Procurar por erros JavaScript
3. Verificar se `BaseActionCableConnector` está sendo inicializado

Comando para debugar:
```javascript
// No console do navegador
console.log(window.App?.$store?.getters?.getCurrentUser)
// Deve retornar objeto do usuário

console.log(window.chatwootConfig?.pubsubToken)
// Deve retornar token válido (string)
```

---

### Q: Apenas alguns agentes são afetados

**A**: Provavelmente relacionado ao browser/configuração local:

**Verificar**:
- Versão do browser (Chrome, Firefox, Edge)
- Extensões que bloqueiam JavaScript/WebSocket (AdBlock, etc.)
- Firewall corporativo bloqueando WebSocket
- VPN instável

**Teste**:
- Abrir em **janela anônima** (sem extensões)
- Testar em **outro browser**
- Desabilitar VPN temporariamente

---

### Q: Problema acontece sempre no mesmo horário

**A**: Pode ser relacionado a:
- **Backup/manutenção** no servidor (Redis restart, etc.)
- **Pico de uso** (muitos usuários → servidor sobrecarregado)
- **Rotina do usuário** (almoço, pausa → aba fica inativa)

**Investigar**:
```bash
# Logs do Redis
docker logs redis_container | grep -i "restart\|shutdown\|error"

# Logs do Rails
tail -f log/production.log | grep -E "ActionCable|WebSocket"
```

---

## Arquivos Relacionados

### Backend
- `app/channels/room_channel.rb` - WebSocket channel
- `app/models/concerns/availability_statusable.rb` - Lógica de status
- `lib/online_status_tracker.rb` - Gerenciamento de presença no Redis
- `app/models/user.rb` - Modelo com pubsub_token

### Frontend
- `app/javascript/shared/helpers/BaseActionCableConnector.js` - Heartbeat logic
- `app/javascript/dashboard/helper/actionCable.js` - Event handlers
- `app/javascript/dashboard/App.vue` - ActionCable initialization

### Configuração
- `.env` - PRESENCE_DURATION
- `config/cable.yml` - ActionCable configuration
- `nginx.conf` (se usar) - Proxy WebSocket configuration

### Documentação Relacionada
- `docs/md/auto_offline.md` - Auto-offline feature
- `docs/md/redis_presence_sync.md` - Redis sync issues
- `.claude/skills/chatwoot-agent-presence.md` - Presence system skill

---

## Caso Real: 16 Agentes Offline Simultaneamente

### Situação

```
Total: 16 de 33 agentes (48%) com WebSocket morto

Categorias:
- 🔴 4 agentes: heartbeat < 2 min (acabaram de cair)
- 🟠 3 agentes: heartbeat 7-42 min (provavelmente ainda logados)
- 🟡 7 agentes: heartbeat 2-2.5h (podem estar logados)
- ⚪ 2 agentes: heartbeat > 3 dias (deslogados)
```

### Diagnóstico

Monitoramento de agente específico (Alane) mostrou:
```
14:46:43 | 18s  | ✅ | online  ← Último heartbeat válido
14:46:48 | 23s  | ❌ | offline ← Expirou (> 20s)
14:46:53 | 28s  | ❌ | offline
14:46:58 | 33s  | ❌ | offline
14:47:03 | 38s  | ❌ | offline ← NENHUM novo heartbeat
```

**Conclusão**: WebSocket morto, nenhum heartbeat novo sendo enviado.

### Solução Aplicada

```ruby
# 1. Regenerar tokens de todos os 16 agentes
dead_agents.each do |user|
  user.regenerate_pubsub_token
  user.save!

  # Limpar Redis
  Redis::Alfred.zrem("ONLINE_PRESENCE::1::USERS", user.id)
  OnlineStatusTracker.set_status(1, user.id, 'offline')
end

# 2. Notificar agentes para logout/login

# 3. Monitorar pós-fix
```

### Resultado

```
Após 10 minutos:
✅ 12 agentes reconectaram (75% recovery)
⚠️  4 agentes ainda offline (não fizeram logout/login)

Após 30 minutos:
✅ 15 agentes reconectaram (93% recovery)
❌ 1 agente não estava mais no escritório (foi embora)
```

**Tempo de resolução**: ~10 minutos para maioria
**Downtime**: Zero para outros serviços
**Impacto**: Nenhum (agentes offline não podiam receber conversas mesmo)

---

## Conclusão

**Problema**: WebSocket desconecta e não reconecta automaticamente → Heartbeat para → Agente offline

**Causa Principal**: Browser suspendendo abas inativas (economia de recursos)

**Solução Imediata**: Regenerar `pubsub_token` + Forçar logout/login

**Prevenção**:
1. Aumentar `PRESENCE_DURATION` (40s ao invés de 20s)
2. Configurar proxy corretamente para WebSocket
3. Monitoramento contínuo (rake task + cron)
4. Orientar usuários a manter aba ativa

**Monitoramento**: Verificar health check periodicamente para detectar problema antes de impactar operação.
