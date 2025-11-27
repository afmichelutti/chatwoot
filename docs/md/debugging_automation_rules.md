# Debugging Automation Rules - Chatwoot

## Visão Geral

Este guia explica como debugar regras de automação que não estão sendo acionadas como esperado no Chatwoot.

## Arquitetura das Automações

### Fluxo Completo

```
1. Mensagem Criada
   ↓
2. after_create_commit callback
   ↓
3. execute_after_create_commit_callbacks
   ↓
4. dispatch_create_events
   ↓
5. Dispatcher envia evento MESSAGE_CREATED
   ↓
6. AutomationRuleListener.message_created recebe evento
   ↓
7. Verifica se deve ignorar mensagem
   ↓
8. Para cada regra ativa:
   - AutomationRules::ConditionsFilterService avalia condições
   - Se match → AutomationRules::ActionService executa ações
```

### Arquivos Envolvidos

| Arquivo | Responsabilidade |
|---------|------------------|
| [app/models/message.rb:300-309](../../app/models/message.rb#L300-L309) | Dispara eventos após criar mensagem |
| [app/models/message.rb:335-344](../../app/models/message.rb#L335-L344) | Método `dispatch_create_events` |
| [app/listeners/automation_rule_listener.rb:18-35](../../app/listeners/automation_rule_listener.rb#L18-L35) | Listener que processa evento |
| [app/listeners/automation_rule_listener.rb:82-85](../../app/listeners/automation_rule_listener.rb#L82-L85) | Lógica de ignorar mensagens |
| [app/services/automation_rules/conditions_filter_service.rb](../../app/services/automation_rules/conditions_filter_service.rb) | Avaliação de condições |
| [app/services/automation_rules/action_service.rb](../../app/services/automation_rules/action_service.rb) | Execução de ações |

## Quando Mensagens São Ignoradas

O `AutomationRuleListener` **ignora automaticamente** mensagens nos seguintes casos:

### 1. Mensagens do Tipo "Activity" (message_type == 2)

Mensagens de atividade são mensagens de sistema (ex: "Conversa atribuída ao João"). Elas não devem acionar automações.

```ruby
# app/listeners/automation_rule_listener.rb:84
def ignore_message_created_event?(event)
  message = event.data[:message]
  performed_by_automation?(event) || message.activity? || message.auto_reply_email?
end
```

**Tipos de Mensagem:**
- `incoming` (0) - Mensagens recebidas de clientes
- `outgoing` (1) - Mensagens enviadas por agentes
- `activity` (2) - **Mensagens de sistema (IGNORADAS)**
- `template` (3) - Mensagens de template

### 2. Auto-reply Email (message.auto_reply_email?)

Emails de auto-resposta não acionam automações.

### 3. Executado por Automação (performed_by_automation?)

Para evitar loops infinitos, mensagens criadas por automações não acionam outras automações.

```ruby
def performed_by_automation?(event)
  event.data[:performed_by].present? && event.data[:performed_by].instance_of?(AutomationRule)
end
```

## Ferramentas de Debug

### Rake Task: Debug Mensagem Específica

Criamos uma rake task para debugar uma mensagem específica e verificar por que uma automação não foi acionada:

```bash
# Debugar mensagem específica
bundle exec rake chatwoot:debug_automation MESSAGE_ID=12345

# Listar mensagens recentes com seus tipos
bundle exec rake chatwoot:list_recent_messages ACCOUNT_ID=1 LIMIT=20
```

**Arquivo:** [lib/tasks/debug_automation.rake](../../lib/tasks/debug_automation.rake)

### O que a Task de Debug Mostra

1. **Detalhes da Mensagem:**
   - ID, conteúdo, tipo (incoming/outgoing/activity)
   - Sender (User, Contact, AgentBot)
   - Se é mensagem de atividade
   - Se é auto-reply

2. **Regras de Automação:**
   - Lista todas as regras ativas para `message_created`
   - Verifica se a mensagem seria ignorada
   - Testa as condições contra a mensagem
   - Mostra qual condição não foi atendida

3. **Análise Detalhada de Condições:**
   - Para condições de `content`: verifica se o texto contém as palavras-chave
   - Para condições de `message_type`: verifica se o tipo bate
   - Mostra resultado de cada condição individualmente

## Problema Comum: Mensagens de Robôs/Bots

### Sintoma

- Mensagens enviadas **internamente pela plataforma** (por agentes) acionam automações ✅
- Mensagens enviadas **por robôs externos** (via API) **não** acionam automações ❌

### Possíveis Causas

#### Causa 1: Tipo de Mensagem Incorreto

Se o robô está enviando mensagens que são criadas como `activity` em vez de `incoming` ou `outgoing`, elas serão ignoradas.

**Como verificar:**
```bash
bundle exec rake chatwoot:list_recent_messages ACCOUNT_ID=1 LIMIT=50
```

Procure mensagens do robô na lista. Se aparecerem como "📋 ACT" (activity), esse é o problema.

#### Causa 2: Condição `message_type` na Regra

Sua regra de automação pode ter uma condição que filtra apenas mensagens `incoming` (recebidas), mas mensagens do robô podem estar sendo criadas como `outgoing` (enviadas).

**Exemplo de regra que só funciona para incoming:**
```json
{
  "conditions": [
    {
      "attribute_key": "message_type",
      "filter_operator": "equal_to",
      "values": ["0"]  // 0 = incoming
    },
    {
      "attribute_key": "content",
      "filter_operator": "contains",
      "values": ["revisão", "12 meses"]
    }
  ]
}
```

**Como verificar:**
1. Vá em Configurações → Automações
2. Abra a regra que não está funcionando
3. Verifique se há uma condição de "Tipo de Mensagem"
4. Se sim, tente remover essa condição ou adicionar "outgoing" também

#### Causa 3: Robô Está Criando Mensagens via API Errada

Se o robô está usando diretamente a API de mensagens do Chatwoot em vez da API do WhatsApp, pode estar criando mensagens sem disparar os callbacks corretos.

**Correto:** Robô envia via API WhatsApp → Webhook → `Whatsapp::IncomingMessageService` → Mensagem criada com callbacks

**Incorreto:** Robô envia via API Chatwoot diretamente → Mensagem criada sem callbacks

#### Causa 4: Mensagens Antigas vs Novas

Se você está testando com mensagens antigas (criadas antes da automação ser configurada), elas não vão acionar a automação. Automações só funcionam em **tempo real** quando a mensagem é criada.

### Como Investigar

#### Passo 1: Identificar ID da Mensagem

1. Abra a conversa no Chatwoot
2. Clique na mensagem que deveria ter acionado a automação
3. Inspecione o elemento (F12) e encontre o `data-message-id`

Ou via Rails Console:
```ruby
# Última mensagem de uma conversa específica
Message.where(conversation_id: 123).order(created_at: :desc).first.id

# Última mensagem com texto específico
Message.where("content ILIKE ?", "%revisão%").order(created_at: :desc).first.id
```

#### Passo 2: Debugar a Mensagem

```bash
bundle exec rake chatwoot:debug_automation MESSAGE_ID=<id_da_mensagem>
```

#### Passo 3: Analisar Output

O output vai mostrar:

1. **Se a mensagem foi ignorada:**
   ```
   ❌ YES - Message is of type 'activity'
   ℹ️  Activity messages are system messages and don't trigger automations
   ```

2. **Se as condições não foram atendidas:**
   ```
   ❌ CONDITIONS DO NOT MATCH

   🔍 DETAILED CONDITION ANALYSIS:
   1. content contains ["revisão", "12 meses"]
      ✅ Message content CONTAINS 'revisão'
      ❌ Message content DOES NOT contain '12 meses'  // <-- PROBLEMA
   ```

3. **Se deveria ter funcionado mas não funcionou:**
   ```
   ✅ NO - Message would NOT be ignored
   ✅ CONDITIONS MATCH - Automation SHOULD trigger
   ```

   Neste caso, há um bug ou a automação foi criada/ativada **depois** da mensagem.

## Rails Console - Comandos Úteis

### Verificar Regras de Automação Ativas

```ruby
# Todas as regras ativas de message_created
AutomationRule.where(event_name: 'message_created', active: true)

# Regras ativas de uma conta específica
AutomationRule.where(
  event_name: 'message_created',
  account_id: 1,
  active: true
).each do |rule|
  puts "#{rule.id}: #{rule.name}"
  puts "  Conditions: #{rule.conditions}"
  puts "  Actions: #{rule.actions}"
end
```

### Testar Condições Manualmente

```ruby
# Carregar mensagem e conversa
message = Message.find(12345)
conversation = message.conversation
rule = AutomationRule.find(10)

# Testar condições
service = AutomationRules::ConditionsFilterService.new(
  rule,
  conversation,
  { message: message }
)

match = service.perform
puts match ? "✅ Match!" : "❌ No match"
```

### Verificar Tipo de Mensagem

```ruby
message = Message.find(12345)

puts "Message Type: #{message.message_type}"
puts "Message Type Raw: #{message.message_type_before_type_cast}"
puts "Is Activity?: #{message.activity?}"
puts "Is Incoming?: #{message.incoming?}"
puts "Is Outgoing?: #{message.outgoing?}"
puts "Sender: #{message.sender_type} ##{message.sender_id}"

if message.sender.is_a?(User)
  puts "Sender is User: #{message.sender.name}"
elsif message.sender.is_a?(Contact)
  puts "Sender is Contact: #{message.sender.name}"
elsif message.sender.is_a?(AgentBot)
  puts "Sender is AgentBot: #{message.sender.name}"
end
```

### Simular Evento Manualmente

```ruby
# CUIDADO: Isso vai executar as ações da automação!
message = Message.find(12345)

# Disparar evento manualmente
Rails.configuration.dispatcher.dispatch(
  'message.created',
  Time.zone.now,
  message: message,
  performed_by: nil
)
```

## Logs

### Habilitar Logs de Automação

No ambiente de desenvolvimento ou staging, você pode adicionar logs extras:

**Arquivo:** `app/listeners/automation_rule_listener.rb`

```ruby
def message_created(event)
  message = event.data[:message]

  Rails.logger.info "=== AUTOMATION DEBUG ==="
  Rails.logger.info "Message ID: #{message.id}"
  Rails.logger.info "Message Type: #{message.message_type}"
  Rails.logger.info "Is Activity?: #{message.activity?}"
  Rails.logger.info "Ignore?: #{ignore_message_created_event?(event)}"

  return if ignore_message_created_event?(event)

  # ... resto do código
end
```

### Verificar Logs em Produção

```bash
# Logs do Rails
tail -f log/production.log | grep -i "automation"

# Logs do Sidekiq (se automações usarem jobs)
tail -f log/sidekiq.log | grep -i "automation"
```

## Casos de Uso Comuns

### Caso 1: Automação Funciona para Agentes mas Não para Bots

**Problema:** Mensagens enviadas por agentes acionam automações, mas mensagens de bots não.

**Solução:**
1. Verifique se a regra tem condição de `message_type: incoming`
2. Mensagens de bots podem ser `outgoing`
3. Remova a condição de tipo ou adicione `outgoing` também

### Caso 2: Automação Não Aciona para Mensagens do WhatsApp

**Problema:** Automação funciona para outros canais mas não para WhatsApp.

**Solução:**
1. Verifique se a regra tem condição de `inbox_id` que não inclui o inbox do WhatsApp
2. Verifique os logs do webhook do WhatsApp: `Whatsapp::IncomingMessageService`
3. Teste com o rake task de debug

### Caso 3: Automação Parou de Funcionar Depois de Atualização

**Problema:** Automação funcionava e parou após atualizar o Chatwoot.

**Solução:**
1. Verifique se a estrutura das condições mudou
2. Verifique os logs de erro: `AutomationRules::ConditionsFilterService`
3. Revalide a regra:
   ```ruby
   rule = AutomationRule.find(10)
   AutomationRules::ConditionValidationService.new(rule).perform
   ```

## Troubleshooting

### ❌ "Nenhuma automação sendo executada"

**Verificações:**

1. Regra está ativa?
   ```ruby
   AutomationRule.find(10).active?
   ```

2. Regra está na conta correta?
   ```ruby
   AutomationRule.find(10).account_id == message.account_id
   ```

3. Evento está correto?
   ```ruby
   AutomationRule.find(10).event_name == 'message_created'
   ```

### ❌ "Condições deveriam bater mas não batem"

**Verificações:**

1. Conteúdo da mensagem tem as palavras?
   ```ruby
   message = Message.find(12345)
   message.content.downcase.include?("revisão")
   ```

2. Use `processed_message_content` em vez de `content`:
   ```ruby
   message.processed_message_content.downcase.include?("revisão")
   ```

3. Cuidado com acentos e espaços extras:
   ```ruby
   # Pode não funcionar
   "revisao" != "revisão"

   # Use I18n.transliterate se necessário
   I18n.transliterate("revisão") # => "revisao"
   ```

### ❌ "Ações não são executadas mesmo com match"

**Verificações:**

1. Verifique erros de execução:
   ```ruby
   # Executar manualmente e ver erros
   rule = AutomationRule.find(10)
   conversation = Conversation.find(123)

   AutomationRules::ActionService.new(rule, rule.account, conversation).perform
   ```

2. Verifique se os IDs nas ações são válidos:
   ```ruby
   # Se ação é assign_agent
   rule.actions # => [{ action_name: 'assign_agent', action_params: [999] }]
   User.find(999) # Existe?
   ```

## Referências

- [app/models/automation_rule.rb](../../app/models/automation_rule.rb)
- [app/listeners/automation_rule_listener.rb](../../app/listeners/automation_rule_listener.rb)
- [app/services/automation_rules/conditions_filter_service.rb](../../app/services/automation_rules/conditions_filter_service.rb)
- [app/services/automation_rules/action_service.rb](../../app/services/automation_rules/action_service.rb)
- [lib/filters/filter_keys.yml](../../lib/filters/filter_keys.yml)

---

**Última atualização:** 2025-01-19
**Versão do Chatwoot:** 4.7.0+
