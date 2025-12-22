# Prevenir Auto-Offline via WebSocket Disconnect

**Data:** 2025-11-28
**Problema:** Agentes com `auto_offline: false` ainda ficam offline ao mudar de aba (WebSocket desconecta)
**Solução:** Bloquear mudanças de status para `offline` quando `auto_offline: false`

---

## 🔍 Análise do Problema

### Sistema atual (antes da fix):

O Chatwoot possui **2 sistemas de presença** que operam simultaneamente:

#### 1. **Sistema WebSocket Nativo do Chatwoot** (imediato, segundos)
- Controla presença via Redis
- Marca `offline` **imediatamente** quando WebSocket desconecta
- **NÃO respeita** a flag `auto_offline`
- Localização: `app/models/account_user.rb` (callbacks de availability)

#### 2. **Nosso ActivityBasedPresenceJob** (periódico, minutos)
- Roda a cada 1 minuto via Sidekiq Cron
- Respeita timeout configurável (ex: 10 minutos)
- **Só atua** quando `auto_offline: false`
- Localização: `app/jobs/activity_based_presence_job.rb`

### 🐛 Problema identificado:

Quando um agente com `auto_offline: false` muda de aba no navegador:

1. **Navegador coloca aba em background** (economia de bateria/CPU)
2. **WebSocket desconecta** (conexão pausada)
3. **Sistema nativo do Chatwoot detecta desconexão**
4. **Marca como `offline` IMEDIATAMENTE** (ignora `auto_offline: false`)
5. **Nosso job não consegue prevenir** (já foi marcado offline)

**Tempo até offline:** ~10 segundos ❌
**Tempo esperado:** 10 minutos ✅

---

## 🎯 Objetivo da Feature

**Bloquear mudanças automáticas para `offline`** quando:
- `auto_offline: false` (agente gerenciado pelo nosso sistema)
- **E** a mudança **NÃO** veio do nosso `ActivityBasedPresenceJob`

**Permitir mudanças para `offline`** quando:
- `auto_offline: true` (agente gerencia manualmente)
- **OU** mudança veio do nosso `ActivityBasedPresenceJob`
- **OU** mudança foi manual pelo próprio agente

---

## ✅ Solução Implementada

### 1. **Adicionar callback `before_update` no `AccountUser` model**

**Arquivo:** `app/models/account_user.rb`

**Lógica:**
```ruby
before_update :prevent_websocket_auto_offline, if: :availability_changed?

private

def prevent_websocket_auto_offline
  return true if auto_offline? # Permite mudanças se auto_offline = true
  return true unless account.activity_based_presence_enabled? # Só atua se sistema habilitado
  return true if availability_was != 'offline' && availability == 'offline' && caller_is_activity_job?

  # Bloqueia mudança para offline se não veio do nosso job
  if availability_was != 'offline' && availability == 'offline'
    Rails.logger.info "[ActivityPresence] Blocked WebSocket auto-offline for #{user.email}"
    self.availability = availability_was # Restaura status anterior
  end
end

def caller_is_activity_job?
  # Verifica se a mudança veio do ActivityBasedPresenceJob
  caller.any? { |line| line.include?('activity_based_presence_job.rb') }
end
```

### 2. **Adicionar flag de contexto no job**

**Arquivo:** `app/jobs/activity_based_presence_job.rb`

**Modificação:**
```ruby
# Marcar que a mudança vem do job (bypass da validação)
Thread.current[:activity_job_update] = true
account_user.update!(availability: 'offline')
Thread.current[:activity_job_update] = nil
```

---

## 🔧 Implementação Detalhada

### Arquivos modificados:

1. **app/models/account_user.rb**
   - Adicionar callback `before_update :prevent_websocket_auto_offline`
   - Adicionar método privado `prevent_websocket_auto_offline`
   - Adicionar método privado `caller_is_activity_job?`

2. **app/jobs/activity_based_presence_job.rb**
   - Adicionar flag `Thread.current[:activity_job_update]` antes do update
   - Limpar flag após update

---

## 📊 Comportamento Esperado

### Cenário 1: Agente com `auto_offline: false` muda de aba

**Antes da fix:**
1. Muda de aba → WebSocket desconecta
2. Sistema nativo marca `offline` (10 segundos)
3. ❌ Agente fica offline imediatamente

**Depois da fix:**
1. Muda de aba → WebSocket desconecta
2. Sistema nativo **tenta** marcar `offline`
3. ✅ **Callback bloqueia** a mudança
4. ✅ Agente continua `online`
5. ✅ Só vai para `offline` após 10 minutos (nosso job)

---

### Cenário 2: Agente com `auto_offline: true` muda de aba

**Comportamento (não muda):**
1. Muda de aba → WebSocket desconecta
2. Sistema nativo marca `offline` (10 segundos)
3. ✅ Callback **permite** (auto_offline = true)
4. ✅ Agente fica offline imediatamente (comportamento nativo)

---

### Cenário 3: ActivityBasedPresenceJob marca offline

**Comportamento:**
1. Job roda a cada 1 minuto
2. Detecta inatividade > 10 minutos
3. Job seta flag `Thread.current[:activity_job_update] = true`
4. Job executa `account_user.update!(availability: 'offline')`
5. ✅ Callback **permite** (veio do job)
6. ✅ Agente marcado como `offline`

---

### Cenário 4: Agente marca status manualmente

**Comportamento:**
1. Agente clica em "Disponibilidade" → "Offline"
2. Frontend envia request para API
3. API atualiza `availability: 'offline'`
4. ✅ Callback **permite** (mudança manual via API)
5. ✅ Status atualizado para `offline`

---

## 🎯 Configuração

### Habilitar o sistema para uma conta:

```ruby
account = Account.find(1)
account.update!(
  activity_based_presence_enabled: true,
  activity_based_presence_config: {
    inactivity_timeout_minutes: 10,
    busy_timeout_hours: 3
  }
)
```

### Configurar agente para ser gerenciado pelo sistema:

```ruby
user = User.find_by(email: 'agente@exemplo.com')
account_user = AccountUser.find_by(account_id: 1, user: user)
account_user.update!(auto_offline: false)
```

### Configurar agente para gerenciar status manualmente:

```ruby
account_user.update!(auto_offline: true)
```

---

## 📋 Checklist de Testes

- [ ] Agente com `auto_offline: false` muda de aba por 30 segundos → Continua online ✅
- [ ] Agente com `auto_offline: false` fica inativo por 10 minutos → Vai para offline ✅
- [ ] Agente com `auto_offline: true` muda de aba por 10 segundos → Vai para offline ✅
- [ ] Agente marca status manualmente para offline → Muda para offline ✅
- [ ] Agente marca status manualmente para online → Muda para online ✅
- [ ] ActivityBasedPresenceJob marca offline após timeout → Funciona ✅

---

## 🔍 Debugging

### Ver logs do callback:

```bash
# Nos logs do Rails (Terminal 1):
grep "ActivityPresence" log/development.log

# Procurar por:
[ActivityPresence] Blocked WebSocket auto-offline for agente@exemplo.com
```

### Verificar configuração no Rails Console:

```ruby
account = Account.find(1)
puts "Sistema habilitado? #{account.activity_based_presence_enabled?}"
puts "Config: #{account.activity_based_presence_config}"

AccountUser.where(account_id: 1).group(:auto_offline).count
# Deve mostrar: {false => X, true => Y}
```

---

## ⚠️ Limitações Conhecidas

1. **Frontend pode mostrar "offline" temporariamente**
   - O WebSocket pode indicar offline no frontend
   - Mas o backend bloqueia a mudança no banco
   - Frontend sincroniza após alguns segundos via polling/WebSocket

2. **Não previne mudanças manuais**
   - Se o agente clicar manualmente em "Offline", será respeitado
   - Isso é intencional (agente deve ter controle manual)

3. **Requer Sidekiq rodando**
   - O job periódico precisa estar ativo
   - Verificar: `Sidekiq::Cron::Job.find('activity_based_presence_job')`

---

## 📝 Notas Técnicas

### Por que usar `Thread.current` em vez de parâmetro?

- O método `update!` do ActiveRecord não aceita parâmetros customizados
- `Thread.current` é thread-safe e escopo limitado
- Limpa automaticamente após o update (evita vazamento de contexto)

### Por que `before_update` em vez de `before_save`?

- `before_save` roda em creates e updates
- `before_update` roda **apenas** em updates (nosso caso)
- Mais eficiente e específico

### Por que verificar `availability_changed?`?

- Só roda o callback se `availability` mudou
- Evita processamento desnecessário
- Melhora performance

---

## 🔗 Arquivos Relacionados

- [app/models/account_user.rb](../../app/models/account_user.rb)
- [app/jobs/activity_based_presence_job.rb](../../app/jobs/activity_based_presence_job.rb)
- [docs/activity-based-presence.md](../activity-based-presence.md) (documentação principal)

---

## 🚀 Deploy

### Checklist:

- [ ] Commit das mudanças
- [ ] Build da imagem Docker
- [ ] Deploy no Portainer
- [ ] Reiniciar Sidekiq (reload do job)
- [ ] Testar em produção

### Comandos:

```bash
# Commit
git add app/models/account_user.rb app/jobs/activity_based_presence_job.rb
git commit -m "feat: Prevent WebSocket auto-offline for managed agents"

# Build
docker build -t afmichelutti/omniflex_cw_470:latest .

# Push
docker push afmichelutti/omniflex_cw_470:latest

# Deploy via Portainer (UI)
```

---

**Autor:** Claude Code
**Referência:** Issue - Agentes ficando offline ao mudar de aba (10 segundos)
