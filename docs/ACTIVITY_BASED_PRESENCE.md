# Activity-Based Presence Feature

Documentação completa da funcionalidade de **Presença Baseada em Atividade** implementada no Chatwoot.

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Arquitetura](#arquitetura)
- [Regras de Negócio](#regras-de-negócio)
- [Implementação Técnica](#implementação-técnica)
- [Configuração](#configuração)
- [Testes](#testes)
- [Troubleshooting](#troubleshooting)

---

## Visão Geral

### Problema

Anteriormente, o Chatwoot dependia exclusivamente de WebSocket heartbeats para gerenciar a disponibilidade dos agentes. Isso causava problemas:

- Agentes marcados como online mesmo quando inativos
- Heartbeats falhando devido a problemas de rede
- Sem controle granular sobre timeouts de inatividade
- Status "busy" esquecidos pelos agentes, ficando presos nesse estado

### Solução

A funcionalidade de **Activity-Based Presence** gerencia automaticamente a disponibilidade dos agentes com base em sua atividade de mensagens:

✅ **Agente envia mensagem** → Marcado como ONLINE
✅ **Sem mensagem por X minutos** → Marcado como OFFLINE
✅ **Status BUSY < Y horas** → Mantido (pausa intencional)
✅ **Status BUSY > Y horas** → Marcado como OFFLINE (esqueceu de mudar)

### Benefícios

- ✅ Gerenciamento automático de disponibilidade
- ✅ Configurável por conta (account)
- ✅ Respeita pausas intencionais (status BUSY)
- ✅ Detecta esquecimento de mudança de status
- ✅ UI intuitiva para configuração
- ✅ Internacionalização completa (EN + PT-BR)

---

## Arquitetura

### Visão Geral

```
┌──────────────────────────────────────────────────────────────┐
│ Sidekiq Scheduler (sidekiq-cron)                             │
│ Executa a cada 1 minuto                                      │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ ActivityBasedPresenceJob                                     │
│ - Busca accounts com feature habilitada                      │
│ - Para cada account, processa agentes                        │
│ - Aplica regras de negócio                                   │
│ - Atualiza availability via Rails model                      │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ AccountUser Model                                            │
│ - after_save callback                                        │
│ - Sincroniza automaticamente com Redis                       │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│ Redis (Presence Tracking)                                    │
│ - ONLINE_PRESENCE:1 (Hash)                                   │
│ - ONLINE_STATUS:1:User:123 (String)                          │
└──────────────────────────────────────────────────────────────┘
```

### Componentes

1. **Database (PostgreSQL)**
   - `accounts.activity_based_presence_enabled` (boolean)
   - `accounts.activity_based_presence_config` (jsonb)

2. **Background Job (Sidekiq)**
   - `ActivityBasedPresenceJob`
   - Executado a cada 1 minuto via sidekiq-cron

3. **Model Callbacks**
   - `AccountUser#after_save` sincroniza com Redis

4. **API Endpoint**
   - `PUT /api/v1/accounts/:id`
   - Aceita parâmetros de configuração

5. **Frontend (Vue.js)**
   - Componente `ActivityBasedPresence.vue`
   - Integrado na página de Account Settings

6. **i18n**
   - Traduções em EN e PT-BR

---

## Regras de Negócio

### Regra 1: Envio de Mensagem = Online

```ruby
if last_message && last_message.created_at > inactivity_timeout.ago
  return 'online'
end
```

**Quando:** Agente enviou mensagem recentemente
**Ação:** Marcar como ONLINE
**Tempo:** Dentro do `inactivity_timeout_minutes`

**Exemplo:**
- Timeout configurado: 10 minutos
- Agente enviou mensagem há 5 minutos
- **Resultado:** ONLINE

### Regra 2: Status BUSY Esquecido = Offline

```ruby
if account_user.availability == 'busy' &&
   account_user.updated_at < busy_timeout.ago
  return 'offline'
end
```

**Quando:** Agente está em BUSY há muito tempo
**Ação:** Forçar OFFLINE
**Tempo:** Mais de `busy_timeout_hours`

**Exemplo:**
- Busy timeout configurado: 3 horas
- Agente em BUSY há 4 horas
- **Resultado:** OFFLINE (esqueceu de mudar)

**Log gerado:**
```
[ActivityPresence] User 123 in BUSY for 4.2h → forcing OFFLINE
```

### Regra 3: Status BUSY Intencional = Manter

```ruby
return 'busy' if account_user.availability == 'busy'
```

**Quando:** Agente está em BUSY há menos tempo
**Ação:** Manter BUSY (respeitar pausa)
**Tempo:** Dentro do `busy_timeout_hours`

**Exemplo:**
- Busy timeout configurado: 3 horas
- Agente em BUSY há 1 hora
- **Resultado:** BUSY (pausa intencional, respeitada)

### Regra 4: Inatividade Prolongada = Offline

```ruby
'offline'
```

**Quando:** Nenhuma outra regra se aplica
**Ação:** Marcar como OFFLINE

**Exemplo:**
- Agente não está BUSY
- Última mensagem há 30 minutos (timeout: 10min)
- **Resultado:** OFFLINE

### Ordem de Precedência

```
1. Enviou mensagem recentemente? → ONLINE
2. BUSY há muito tempo? → OFFLINE
3. BUSY há pouco tempo? → BUSY
4. Caso contrário → OFFLINE
```

### Filtros Importantes

**✅ Apenas agentes com `auto_offline = false` são processados:**

```ruby
account.account_users.where(auto_offline: false).find_each do |account_user|
  # ...
end
```

**Motivo:** Agentes com `auto_offline = true` já têm gerenciamento automático via heartbeat.

**✅ Apenas mensagens OUTGOING são consideradas:**

```ruby
Message.where(
  message_type: Message.message_types[:outgoing]
)
```

**Tipos de mensagem:**
- `0` = incoming (cliente → agente)
- `1` = outgoing (agente → cliente) ✅ **Usado**
- `2` = activity (sistema)

---

## Implementação Técnica

### Arquivos Criados/Modificados

#### 1. Migration

**Arquivo:** `db/migrate/20250118000000_add_activity_based_presence_to_accounts.rb`

```ruby
class AddActivityBasedPresenceToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :activity_based_presence_enabled, :boolean,
               default: false, null: false
    add_column :accounts, :activity_based_presence_config, :jsonb,
               default: {
                 inactivity_timeout_minutes: 10,
                 busy_timeout_hours: 3
               }, null: false
  end
end
```

**Executar:**
```bash
bundle exec rails db:migrate
```

#### 2. Background Job

**Arquivo:** `app/jobs/activity_based_presence_job.rb`

```ruby
class ActivityBasedPresenceJob < ApplicationJob
  queue_as :low

  def perform
    Rails.logger.info '[ActivityPresence] Starting job...'

    Account.where(activity_based_presence_enabled: true).find_each do |account|
      process_account_agents(account)
    end

    Rails.logger.info '[ActivityPresence] Job completed'
  end

  private

  def process_account_agents(account)
    config = account.activity_based_presence_config.with_indifferent_access
    inactivity_timeout = config[:inactivity_timeout_minutes].to_i.minutes
    busy_timeout = config[:busy_timeout_hours].to_i.hours

    Rails.logger.info "[ActivityPresence] Processing account #{account.id} (#{account.name})"

    updated_count = 0

    account.account_users.where(auto_offline: false).find_each do |account_user|
      new_status = calculate_status(account_user, inactivity_timeout, busy_timeout)

      if new_status != account_user.availability
        Rails.logger.info(
          "[ActivityPresence] User #{account_user.user.email}: #{account_user.availability} → #{new_status}"
        )

        account_user.update!(availability: new_status)
        updated_count += 1
      end
    end

    Rails.logger.info "[ActivityPresence] Account #{account.id}: #{updated_count} agents updated"
  end

  def calculate_status(account_user, inactivity_timeout, busy_timeout)
    last_message = find_last_outgoing_message(account_user)

    # REGRA 1: Enviou mensagem recentemente → ONLINE
    if last_message && last_message.created_at > inactivity_timeout.ago
      return 'online'
    end

    # REGRA 2: Está em BUSY há mais de X horas → OFFLINE (esqueceu de voltar)
    if account_user.availability == 'busy' &&
       account_user.updated_at < busy_timeout.ago
      Rails.logger.info(
        "[ActivityPresence] User #{account_user.user_id} in BUSY for " \
        "#{((Time.zone.now - account_user.updated_at) / 1.hour).round(1)}h → forcing OFFLINE"
      )
      return 'offline'
    end

    # REGRA 3: Está em BUSY e < X horas → Manter BUSY (respeitar pausa)
    return 'busy' if account_user.availability == 'busy'

    # REGRA 4: Sem mensagem há muito tempo → OFFLINE
    'offline'
  end

  def find_last_outgoing_message(account_user)
    Message.where(
      account_id: account_user.account_id,
      sender_id: account_user.user_id,
      sender_type: 'User',
      message_type: Message.message_types[:outgoing]
    ).order(created_at: :desc).first
  end
end
```

#### 3. Scheduler

**Arquivo:** `config/schedule.yml`

```yaml
activity_based_presence_job:
  cron: '*/1 * * * *'  # A cada 1 minuto
  class: 'ActivityBasedPresenceJob'
  queue: low
```

**⚠️ Limitação:** sidekiq-cron só suporta intervalos de 1 minuto como mínimo.

#### 4. Controller

**Arquivo:** `app/controllers/api/v1/accounts_controller.rb`

Adicionar aos `account_params`:

```ruby
def account_params
  params.permit(
    # ... outros parâmetros
    :activity_based_presence_enabled,
    activity_based_presence_config: [
      :inactivity_timeout_minutes,
      :busy_timeout_hours
    ]
  )
end
```

#### 5. JSON Builder

**Arquivo:** `app/views/api/v1/models/_account.json.jbuilder`

```ruby
json.activity_based_presence_enabled @account.activity_based_presence_enabled
json.activity_based_presence_config @account.activity_based_presence_config
```

#### 6. Vue Component

**Arquivo:** `app/javascript/dashboard/routes/dashboard/settings/account/components/ActivityBasedPresence.vue`

```vue
<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import SectionLayout from './SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import Switch from 'next/switch/Switch.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import NextInput from 'next/input/Input.vue';

const { t } = useI18n();
const isEnabled = ref(false);
const inactivityTimeoutMinutes = ref(10);
const busyTimeoutHours = ref(3);
const isSubmitting = ref(false);

const { currentAccount, updateAccount } = useAccount();

watch(
  currentAccount,
  () => {
    const {
      activity_based_presence_enabled,
      activity_based_presence_config,
    } = currentAccount.value || {};

    isEnabled.value = activity_based_presence_enabled || false;

    if (activity_based_presence_config) {
      inactivityTimeoutMinutes.value = activity_based_presence_config.inactivity_timeout_minutes || 10;
      busyTimeoutHours.value = activity_based_presence_config.busy_timeout_hours || 3;
    }
  },
  { deep: true, immediate: true }
);

const updateAccountSettings = async (enabled, config) => {
  try {
    isSubmitting.value = true;
    await updateAccount({
      activity_based_presence_enabled: enabled,
      activity_based_presence_config: config,
    }, { silent: true });
    useAlert(t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.API.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.API.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

const handleSubmit = async () => {
  if (inactivityTimeoutMinutes.value < 1) {
    useAlert(t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.INACTIVITY_TIMEOUT.ERROR'));
    return Promise.resolve();
  }

  if (busyTimeoutHours.value < 1) {
    useAlert(t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.BUSY_TIMEOUT.ERROR'));
    return Promise.resolve();
  }

  return updateAccountSettings(true, {
    inactivity_timeout_minutes: inactivityTimeoutMinutes.value,
    busy_timeout_hours: busyTimeoutHours.value,
  });
};

const handleDisable = async () => {
  return updateAccountSettings(false, {
    inactivity_timeout_minutes: 10,
    busy_timeout_hours: 3,
  });
};

const toggleActivityPresence = async () => {
  if (!isEnabled.value) {
    handleDisable();
  } else {
    handleSubmit();
  }
};
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.NOTE')"
    :hide-content="!isEnabled"
    with-border
  >
    <template #headerActions>
      <div class="flex justify-end">
        <Switch v-model="isEnabled" @change="toggleActivityPresence" />
      </div>
    </template>

    <form class="grid gap-5" @submit.prevent="handleSubmit">
      <WithLabel
        :label="t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.INACTIVITY_TIMEOUT.LABEL')"
        :help-message="t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.INACTIVITY_TIMEOUT.HELP')"
      >
        <div class="flex gap-2 items-center">
          <NextInput
            v-model.number="inactivityTimeoutMinutes"
            type="number"
            min="1"
            max="999"
            class="w-32"
          />
          <span class="text-sm text-n-slate-11">
            {{ t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.MINUTES') }}
          </span>
        </div>
      </WithLabel>

      <WithLabel
        :label="t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.BUSY_TIMEOUT.LABEL')"
        :help-message="t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.BUSY_TIMEOUT.HELP')"
      >
        <div class="flex gap-2 items-center">
          <NextInput
            v-model.number="busyTimeoutHours"
            type="number"
            min="1"
            max="999"
            class="w-32"
          />
          <span class="text-sm text-n-slate-11">
            {{ t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.HOURS') }}
          </span>
        </div>
      </WithLabel>

      <div class="flex gap-2">
        <NextButton
          blue
          type="submit"
          :is-loading="isSubmitting"
          :label="t('GENERAL_SETTINGS.FORM.ACTIVITY_PRESENCE.UPDATE_BUTTON')"
        />
      </div>
    </form>
  </SectionLayout>
</template>
```

#### 7. Integrar Componente

**Arquivo:** `app/javascript/dashboard/routes/dashboard/settings/account/Index.vue`

```vue
<script>
// Adicionar import
import ActivityBasedPresence from './components/ActivityBasedPresence.vue';

export default {
  components: {
    // ... outros componentes
    ActivityBasedPresence,
  },
  // ...
}
</script>

<template>
  <!-- ... -->
  <AudioTranscription v-if="showAudioTranscriptionConfig" />
  <ActivityBasedPresence />  <!-- Adicionar aqui -->
  <AccountId />
  <!-- ... -->
</template>
```

#### 8. Traduções

**Arquivo EN:** `app/javascript/dashboard/i18n/locale/en/generalSettings.json`

```json
{
  "GENERAL_SETTINGS": {
    "FORM": {
      "ACTIVITY_PRESENCE": {
        "TITLE": "Activity-Based Presence",
        "NOTE": "Automatically manage agent availability based on their messaging activity. Agents will be marked online when sending messages, and offline after a period of inactivity. The system respects 'busy' status as intentional breaks.",
        "INACTIVITY_TIMEOUT": {
          "LABEL": "Inactivity timeout",
          "HELP": "Time without sending messages before marking agent as offline",
          "ERROR": "Inactivity timeout must be at least 1 minute"
        },
        "BUSY_TIMEOUT": {
          "LABEL": "Maximum busy duration",
          "HELP": "If an agent stays 'busy' longer than this, they'll be marked offline (helps catch forgotten status changes)",
          "ERROR": "Busy timeout must be at least 1 hour"
        },
        "MINUTES": "minutes",
        "HOURS": "hours",
        "UPDATE_BUTTON": "Save Changes",
        "API": {
          "SUCCESS": "Activity-based presence settings updated successfully",
          "ERROR": "Failed to update activity-based presence settings"
        }
      }
    }
  }
}
```

**Arquivo PT-BR:** `app/javascript/dashboard/i18n/locale/pt_BR/generalSettings.json`

```json
{
  "GENERAL_SETTINGS": {
    "FORM": {
      "ACTIVITY_PRESENCE": {
        "TITLE": "Presença Baseada em Atividade",
        "NOTE": "Gerencie automaticamente a disponibilidade dos agentes com base em sua atividade de mensagens. Os agentes serão marcados como online ao enviar mensagens e offline após um período de inatividade. O sistema respeita o status 'ocupado' como pausas intencionais.",
        "INACTIVITY_TIMEOUT": {
          "LABEL": "Tempo de inatividade",
          "HELP": "Tempo sem enviar mensagens antes de marcar o agente como offline",
          "ERROR": "O tempo de inatividade deve ser de pelo menos 1 minuto"
        },
        "BUSY_TIMEOUT": {
          "LABEL": "Duração máxima de ocupado",
          "HELP": "Se um agente permanecer 'ocupado' por mais tempo, será marcado como offline (ajuda a detectar esquecimento de mudança de status)",
          "ERROR": "O tempo de ocupado deve ser de pelo menos 1 hora"
        },
        "MINUTES": "minutos",
        "HOURS": "horas",
        "UPDATE_BUTTON": "Salvar Alterações",
        "API": {
          "SUCCESS": "Configurações de presença baseada em atividade atualizadas com sucesso",
          "ERROR": "Falha ao atualizar configurações de presença baseada em atividade"
        }
      }
    }
  }
}
```

---

## Configuração

### Habilitar Feature

1. Fazer login como administrador
2. Ir para **Settings → Account Settings**
3. Procurar seção **"Activity-Based Presence"** / **"Presença Baseada em Atividade"**
4. Ativar o switch
5. Configurar timeouts:
   - **Inactivity timeout:** 10 minutos (padrão)
   - **Maximum busy duration:** 3 horas (padrão)
6. Clicar em **"Save Changes"** / **"Salvar Alterações"**

### Valores Recomendados

| Configuração | Mínimo | Padrão | Máximo | Recomendado |
|--------------|--------|--------|--------|-------------|
| Inactivity timeout | 1 min | 10 min | 999 min | 5-15 min |
| Busy timeout | 1 hora | 3 horas | 999 horas | 2-4 horas |

**Dicas:**

- **Inactivity timeout muito curto** (< 5 min): Agentes marcados offline rapidamente, pode ser frustrante
- **Inactivity timeout muito longo** (> 30 min): Agentes inativos ficam online por muito tempo
- **Busy timeout muito curto** (< 1 hora): Pausas legítimas interrompidas
- **Busy timeout muito longo** (> 8 horas): Status esquecidos não detectados

---

## Testes

### Teste Manual

#### Preparação

```bash
# Habilitar logs detalhados
tail -f log/development.log | grep ActivityPresence
```

#### Teste 1: Envio de Mensagem = Online

1. Agent está offline
2. Agent envia mensagem em uma conversa
3. Aguardar até 1 minuto (próxima execução do job)
4. **Esperado:** Agent marcado como ONLINE

**Log esperado:**
```
[ActivityPresence] User agent@example.com: offline → online
```

#### Teste 2: Inatividade = Offline

1. Agent está online
2. Agent não envia mensagens por > `inactivity_timeout`
3. Aguardar execução do job
4. **Esperado:** Agent marcado como OFFLINE

**Log esperado:**
```
[ActivityPresence] User agent@example.com: online → offline
```

#### Teste 3: BUSY Intencional = Mantido

1. Agent muda status para BUSY manualmente
2. Agent não envia mensagens
3. Tempo < `busy_timeout`
4. **Esperado:** Status BUSY mantido

**Log esperado:**
```
[ActivityPresence] Account 1: 0 agents updated
```

#### Teste 4: BUSY Esquecido = Offline

1. Agent está em BUSY há > `busy_timeout`
2. Aguardar execução do job
3. **Esperado:** Agent marcado como OFFLINE

**Log esperado:**
```
[ActivityPresence] User 123 in BUSY for 4.2h → forcing OFFLINE
[ActivityPresence] User agent@example.com: busy → offline
```

### Teste Automatizado

#### Executar Job Manualmente

```ruby
# No Rails console
ActivityBasedPresenceJob.new.perform
```

#### Simular Cenários

```ruby
# No Rails console

# 1. Habilitar feature
account = Account.first
account.update!(
  activity_based_presence_enabled: true,
  activity_based_presence_config: {
    inactivity_timeout_minutes: 10,
    busy_timeout_hours: 3
  }
)

# 2. Criar agente de teste
user = User.first
account_user = AccountUser.find_by(account: account, user: user)
account_user.update!(auto_offline: false, availability: 'offline')

# 3. Simular envio de mensagem
conversation = account.conversations.first
message = conversation.messages.create!(
  account: account,
  inbox: conversation.inbox,
  sender: user,
  message_type: 'outgoing',
  content: 'Test message'
)

# 4. Executar job
ActivityBasedPresenceJob.new.perform

# 5. Verificar
account_user.reload
puts account_user.availability  # Deve ser 'online'
```

### Verificar Sincronização Redis

```bash
# No terminal
redis-cli

# Verificar presença
GET ONLINE_STATUS:1:User:123
# Deve retornar: "online"

# Verificar hash de presença
HGETALL ONLINE_PRESENCE:1
# Deve incluir: "123" => "online"
```

---

## Troubleshooting

### ❌ Problema: Job não está executando

**Sintomas:** Logs não aparecem, agentes não mudam de status

**Verificar:**

```bash
# 1. Sidekiq rodando?
ps aux | grep sidekiq

# 2. Schedule.yml correto?
cat config/schedule.yml | grep activity

# 3. Job está agendado?
bundle exec rails console
Sidekiq::Cron::Job.all
# Deve incluir: "activity_based_presence_job"
```

**Solução:**

```ruby
# No Rails console
Sidekiq::Cron::Job.load_from_hash(YAML.load_file('config/schedule.yml'))
```

### ❌ Problema: Agentes não sendo processados

**Sintomas:** Log mostra "0 agents updated" sempre

**Verificar:**

```ruby
# No Rails console
account = Account.find(1)

# 1. Feature habilitada?
account.activity_based_presence_enabled
# Deve ser: true

# 2. Agentes com auto_offline = false?
account.account_users.where(auto_offline: false).count
# Deve ser > 0

# 3. Mensagens existem?
Message.where(
  account_id: account.id,
  message_type: 1  # outgoing
).count
# Deve ser > 0
```

### ❌ Problema: Status não sincroniza com Redis

**Sintomas:** Banco de dados atualiza, mas Redis não

**Verificar:**

```ruby
# No Rails console
account_user = AccountUser.first

# 1. Callback está funcionando?
account_user.update!(availability: 'online')

# 2. Verificar Redis
Redis.new.get("ONLINE_STATUS:#{account_user.account_id}:User:#{account_user.user_id}")
# Deve retornar: "online"
```

**Solução:**

Verifique se o model `AccountUser` tem o callback `after_save` para sincronizar Redis.

### ❌ Problema: Tradução não aparece

**Sintomas:** UI em inglês mesmo com idioma PT-BR

**Solução:**

```bash
# 1. Limpar cache
rm -rf node_modules/.vite tmp/cache public/packs

# 2. Reiniciar Vite
# Terminal 3: Ctrl+C
bin/vite dev

# 3. Hard refresh no navegador
# Ctrl+Shift+R
```

### ❌ Problema: Performance degradada

**Sintomas:** Sistema lento após habilitar feature

**Causas possíveis:**

1. Muitos agentes sendo processados simultaneamente
2. Queries N+1
3. Job executando muito frequentemente

**Otimizações:**

```ruby
# Em ActivityBasedPresenceJob

# 1. Adicionar batch processing
account.account_users.where(auto_offline: false).find_in_batches(batch_size: 100) do |batch|
  # ...
end

# 2. Eager loading
account.account_users
  .where(auto_offline: false)
  .includes(:user)
  .find_each do |account_user|
  # ...
end

# 3. Reduzir frequência (em schedule.yml)
# De: */1 * * * * (1 minuto)
# Para: */5 * * * * (5 minutos)
```

---

## Logs

### Formato de Logs

```
[ActivityPresence] Starting job...
[ActivityPresence] Processing account 1 (Nome da Conta)
[ActivityPresence] User agent@example.com: offline → online
[ActivityPresence] User admin@example.com: online → offline
[ActivityPresence] User 123 in BUSY for 4.2h → forcing OFFLINE
[ActivityPresence] User busy@example.com: busy → offline
[ActivityPresence] Account 1: 3 agents updated
[ActivityPresence] Job completed
```

### Monitoramento

```bash
# Ver últimos logs
tail -100 log/development.log | grep ActivityPresence

# Acompanhar em tempo real
tail -f log/development.log | grep ActivityPresence

# Contar execuções
grep "ActivityPresence.*Starting job" log/development.log | wc -l

# Ver apenas mudanças de status
grep "ActivityPresence.*→" log/development.log
```

---

## Referências

- [Chatwoot Presence Tracking](https://www.chatwoot.com/docs)
- [Sidekiq Cron](https://github.com/sidekiq-cron/sidekiq-cron)
- [Rails Active Job](https://guides.rubyonrails.org/active_job_basics.html)

---

**Criado em:** 2025-01-22
**Versão:** 1.0
**Autor:** Equipe de Desenvolvimento
