# Troubleshooting: Automações Não Disparando no Chatwoot

## Visão Geral

Este documento descreve um caso real de troubleshooting onde automações configuradas corretamente não estavam sendo acionadas, e como investigar e resolver esse tipo de problema.

## Caso de Estudo: Automação "Disparo Revisão 12 Meses"

### Sintomas

- **Automação configurada**: "Disparo revisão 12 meses"
- **Evento**: Mensagem Criada
- **Condições**:
  - A mensagem contém "revisão" **E**
  - A mensagem contém "12 meses"
- **Ações**:
  - Atribuir ao agente: Monaha
  - Adicionar labels: `disparo-revisão-12meses`, `disparo-revisão-6meses`
- **Problema**: Automação não estava disparando mesmo com mensagens que continham ambas as palavras

### Contexto da Integração

- **Sistema**: WhatsApp integrado via **WAHA** (WhatsApp HTTP API open-source)
- **Fluxo**: Robô/Sistema Externo → WhatsApp → WAHA → Webhook → Chatwoot
- **Tipo de Mensagens**: Mensagens apareciam no Chatwoot com ícone 📱 "Enviado do WhatsApp"

## Processo de Investigação

### Passo 1: Verificar Tipo de Mensagem

**Hipótese Inicial**: Mensagens podem estar sendo criadas como `activity` em vez de `incoming`/`outgoing`.

**SQL de Diagnóstico**:
```sql
SELECT
  m.id,
  m.message_type,
  CASE
    WHEN m.message_type = 0 THEN 'incoming ⬇️ (aciona automação)'
    WHEN m.message_type = 1 THEN 'outgoing ⬆️ (aciona automação)'
    WHEN m.message_type = 2 THEN 'activity ❌ NUNCA ACIONA'
    WHEN m.message_type = 3 THEN 'template (aciona automação)'
  END as tipo,
  m.sender_type,
  m.content,
  m.created_at
FROM messages m
WHERE m.conversation_id = :conversation_id
  AND m.content ILIKE '%palavra_chave%'
ORDER BY m.created_at DESC;
```

**Descoberta**:
- Mensagens do robô eram criadas como `message_type = 1` (**outgoing**)
- `sender_type = User` (autenticadas como usuário do Chatwoot)
- ✅ **NÃO eram activity**, portanto deveriam acionar automações

**Arquivos Relevantes**:
- [app/listeners/automation_rule_listener.rb:82-85](../../app/listeners/automation_rule_listener.rb#L82-L85) - Mensagens `activity` são ignoradas
- [app/models/message.rb:84](../../app/models/message.rb#L84) - Enum de tipos de mensagem

### Passo 2: Verificar Conteúdo das Mensagens

**Hipótese**: Mensagens podem não conter as palavras-chave exatas ou podem ter problemas de encoding.

**SQL de Diagnóstico**:
```sql
SELECT
  m.id,
  m.message_type,
  m.content,
  m.processed_message_content,
  CASE
    WHEN LOWER(m.processed_message_content) LIKE '%revisão%' THEN 'SIM ✅'
    ELSE 'NÃO ❌'
  END as tem_revisao,
  CASE
    WHEN LOWER(m.processed_message_content) LIKE '%12 meses%' THEN 'SIM ✅'
    ELSE 'NÃO ❌'
  END as tem_12meses,
  CASE
    WHEN LOWER(m.processed_message_content) LIKE '%revisão%'
     AND LOWER(m.processed_message_content) LIKE '%12 meses%' THEN 'DISPARA ✅✅'
    ELSE 'NÃO DISPARA ❌'
  END as atende_automacao,
  m.created_at
FROM messages m
WHERE m.account_id = :account_id
  AND m.message_type IN (0, 1)  -- incoming ou outgoing
  AND (
    LOWER(m.processed_message_content) LIKE '%revisão%'
    OR LOWER(m.processed_message_content) LIKE '%12 meses%'
  )
  AND m.created_at >= '2025-11-01 00:00:00'
ORDER BY m.created_at DESC;
```

**Descoberta**:
- ✅ Mensagens **CONTINHAM** ambas as palavras "revisão" E "12 meses"
- ✅ Campo `processed_message_content` estava correto
- Exemplos encontrados:
  - "vamos agendar a sua revisão de 12 meses?"
  - "Bom dia! A próxima revisão do seu veículo é com 3.000km ou 12 meses"
  - "A revisão de 12 meses ou 5 mil km deve ser feita"

**Arquivos Relevantes**:
- [app/services/automation_rules/conditions_filter_service.rb:115](../../app/services/automation_rules/conditions_filter_service.rb#L115) - Usa `processed_message_content` para matching

### Passo 3: Verificar Configuração da Automação

**Checklist**:
- ✅ Regra está ativa (`active = true`)
- ✅ Evento correto: `message_created`
- ✅ Account ID correto
- ✅ Condições corretas (operador AND entre as duas palavras)
- ✅ **Não há filtro de `message_type`** (aceita tanto incoming quanto outgoing)

**SQL para Verificar**:
```sql
SELECT
  ar.id,
  ar.name,
  ar.event_name,
  ar.active,
  ar.conditions,
  ar.actions,
  ar.account_id,
  ar.created_at,
  ar.updated_at
FROM automation_rules ar
WHERE ar.account_id = :account_id
  AND ar.event_name = 'message_created'
  AND ar.active = true;
```

### Passo 4: Verificar se Evento é Disparado

**Código do Listener**: [app/listeners/automation_rule_listener.rb:18-35](../../app/listeners/automation_rule_listener.rb#L18-L35)

```ruby
def message_created(event)
  message = event.data[:message]

  # Verifica se deve ignorar
  return if ignore_message_created_event?(event)

  account = message.try(:account)
  changed_attributes = event.data[:changed_attributes]

  return unless rule_present?('message_created', account)

  rules = current_account_rules('message_created', account)

  rules.each do |rule|
    conditions_match = ::AutomationRules::ConditionsFilterService.new(rule, message.conversation,
                                                                      { message: message, changed_attributes: changed_attributes }).perform
    ::AutomationRules::ActionService.new(rule, account, message.conversation).perform if conditions_match.present?
  end
end
```

**Condições de Ignorar** (linha 82-85):
```ruby
def ignore_message_created_event?(event)
  message = event.data[:message]
  performed_by_automation?(event) || message.activity? || message.auto_reply_email?
end
```

Mensagens são ignoradas APENAS se:
1. Foi criada por outra automação (`performed_by_automation?`)
2. É mensagem de atividade (`message.activity?`)
3. É auto-reply de email (`message.auto_reply_email?`)

**No nosso caso**: ✅ Nenhuma dessas condições era verdadeira

### Passo 5: Verificar Mensagens via API vs WhatsApp

**Descoberta Importante**: Mensagens criadas via API do Chatwoot (como o WAHA faz) são criadas como `outgoing` por padrão.

**Código**: [app/builders/messages/message_builder.rb:10](../../app/builders/messages/message_builder.rb#L10)

```ruby
@message_type = params[:message_type] || 'outgoing'
```

Isso explica por que mensagens do robô/WAHA aparecem como:
- `message_type = 1` (outgoing)
- `sender_type = User`
- Com ícone 📱 "Enviado do WhatsApp"

**Mas isso NÃO impede automações de disparar!** Automações funcionam para `outgoing` também, a menos que haja filtro específico.

### Passo 6: Hipótese Final - Timing

**CAUSA RAIZ PROVÁVEL**: Automações só funcionam em **tempo real**!

Se a automação foi:
- Criada em: 15/11/2025
- Mas as mensagens foram enviadas em: 13/11/2025

Então a automação **NUNCA vai disparar** para essas mensagens antigas.

**Automações NÃO são retroativas!**

## Solução e Testes

### Teste Definitivo

1. **Verificar quando a automação foi criada/ativada**:
   ```sql
   SELECT
     ar.id,
     ar.name,
     ar.created_at as criada_em,
     ar.updated_at as atualizada_em
   FROM automation_rules ar
   WHERE ar.name = 'Disparo revisão 12 meses';
   ```

2. **Comparar com data das mensagens**:
   ```sql
   SELECT
     MIN(created_at) as primeira_mensagem,
     MAX(created_at) as ultima_mensagem,
     COUNT(*) as total
   FROM messages m
   WHERE m.account_id = :account_id
     AND LOWER(m.processed_message_content) LIKE '%revisão%'
     AND LOWER(m.processed_message_content) LIKE '%12 meses%';
   ```

3. **Teste em Tempo Real**:
   - Enviar uma nova mensagem via WAHA/WhatsApp contendo "revisão de 12 meses"
   - Verificar se a automação dispara imediatamente
   - Se disparar: confirma que o problema era timing
   - Se não disparar: investigar mais a fundo

### Comandos de Debug Úteis

**Usar Rake Task de Debug** (criada em [lib/tasks/debug_automation.rake](../../lib/tasks/debug_automation.rake)):

```bash
# Debugar mensagem específica
bundle exec rake chatwoot:debug_automation MESSAGE_ID=5094690

# Listar mensagens recentes
bundle exec rake chatwoot:list_recent_messages ACCOUNT_ID=71 LIMIT=50
```

**Rails Console - Testar Manualmente**:
```ruby
# Carregar mensagem
message = Message.find(5094690)
conversation = message.conversation

# Carregar regra
rule = AutomationRule.find_by(name: 'Disparo revisão 12 meses')

# Testar condições
service = AutomationRules::ConditionsFilterService.new(
  rule,
  conversation,
  { message: message }
)

match = service.perform
puts match ? "✅ Deveria disparar" : "❌ Não dispara"

# Simular evento (CUIDADO: executa ações!)
Rails.configuration.dispatcher.dispatch(
  'message.created',
  Time.zone.now,
  message: message,
  performed_by: nil
)
```

## Problemas Comuns e Soluções

### Problema 1: Mensagens Activity

**Sintoma**: Mensagens aparecem mas automação não dispara

**Causa**: Mensagens criadas como `message_type = 2` (activity)

**Como identificar**:
```sql
SELECT message_type, COUNT(*)
FROM messages
WHERE conversation_id = :id
GROUP BY message_type;
```

**Solução**: Corrigir integração para criar como `incoming` ou `outgoing`

### Problema 2: Operador AND vs OR

**Sintoma**: Automação com múltiplas condições não dispara

**Causa**: Operador AND exige que TODAS as condições sejam atendidas na MESMA mensagem

**Exemplo**:
```
Condição 1: mensagem contém "revisão" AND
Condição 2: mensagem contém "12 meses"
```

Precisa de mensagem como: "Sua revisão de 12 meses está agendada"

Não funciona com:
- Mensagem 1: "Revisão programada" (só tem "revisão")
- Mensagem 2: "Retorne em 12 meses" (só tem "12 meses")

**Solução**:
- Mudar para operador OR, OU
- Usar condição de labels (evento `conversation_updated`)

### Problema 3: Automações Não São Retroativas

**Sintoma**: Mensagens antigas não acionam automação criada depois

**Causa**: Automações só funcionam em tempo real

**Solução**: Não há solução para mensagens antigas. Para acionamento retroativo, usar scripts manuais.

### Problema 4: Filtro de message_type

**Sintoma**: Automação funciona para mensagens de clientes mas não do robô

**Causa**: Automação tem condição `message_type = incoming` mas robô envia como `outgoing`

**Como verificar**:
```sql
SELECT conditions FROM automation_rules WHERE id = :rule_id;
```

Procurar por:
```json
{
  "attribute_key": "message_type",
  "filter_operator": "equal_to",
  "values": ["0"]  // Apenas incoming
}
```

**Solução**: Remover condição de message_type ou adicionar `outgoing` também

## Alternativa: Usar conversation_updated com Labels

Para cenários onde mensagens vêm de sistemas externos e você quer mais controle:

### Configuração Recomendada

**Evento**: `Conversa Atualizada` (conversation_updated)

**Condições**:
- `Labels` contém `disparo-revisão-12meses`

**Ações**:
- Atribuir ao agente
- Adicionar outras labels

**Vantagens**:
1. ✅ Não depende do texto exato da mensagem
2. ✅ Mais confiável para integrações externas
3. ✅ Pode ser acionado por API diretamente (adição de label)
4. ✅ Não importa se mensagem é incoming/outgoing/activity

**Fluxo**:
1. Sistema externo envia mensagem (qualquer conteúdo)
2. Sistema externo adiciona label via API:
   ```bash
   POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/labels
   {
     "labels": ["disparo-revisão-12meses"]
   }
   ```
3. Automação dispara automaticamente

## Checklist de Troubleshooting

Ao investigar automações que não disparam:

- [ ] Verificar se regra está ativa (`active = true`)
- [ ] Verificar se event_name está correto
- [ ] Verificar se account_id da regra corresponde à mensagem
- [ ] Verificar message_type da mensagem (não pode ser `activity`)
- [ ] Verificar se mensagem contém palavras-chave (usar `processed_message_content`)
- [ ] Verificar operador das condições (AND vs OR)
- [ ] Verificar se há filtro de message_type na automação
- [ ] Verificar timing: regra criada ANTES das mensagens?
- [ ] Testar com nova mensagem em tempo real
- [ ] Usar rake task de debug
- [ ] Verificar logs: `log/production.log` ou `log/development.log`

## SQL Queries de Diagnóstico

### Query Completa de Diagnóstico

```sql
-- Mensagens que deveriam acionar automação
SELECT
  m.id,
  m.conversation_id,
  m.message_type,
  CASE
    WHEN m.message_type = 0 THEN 'incoming ⬇️'
    WHEN m.message_type = 1 THEN 'outgoing ⬆️'
    WHEN m.message_type = 2 THEN 'activity ❌ IGNORADO'
    WHEN m.message_type = 3 THEN 'template'
  END as tipo,
  m.sender_type,
  m.content,
  m.processed_message_content,
  CASE
    WHEN LOWER(m.processed_message_content) LIKE '%palavra1%' THEN 'SIM ✅'
    ELSE 'NÃO ❌'
  END as tem_palavra1,
  CASE
    WHEN LOWER(m.processed_message_content) LIKE '%palavra2%' THEN 'SIM ✅'
    ELSE 'NÃO ❌'
  END as tem_palavra2,
  CASE
    WHEN m.message_type != 2
     AND LOWER(m.processed_message_content) LIKE '%palavra1%'
     AND LOWER(m.processed_message_content) LIKE '%palavra2%' THEN '🎯 DEVERIA DISPARAR'
    WHEN m.message_type = 2 THEN '❌ IGNORADO (activity)'
    ELSE '❌ NÃO ATENDE CONDIÇÕES'
  END as status_automacao,
  m.created_at,
  (
    SELECT ar.created_at
    FROM automation_rules ar
    WHERE ar.name = 'Nome da Regra'
    LIMIT 1
  ) as regra_criada_em,
  CASE
    WHEN m.created_at >= (
      SELECT ar.created_at
      FROM automation_rules ar
      WHERE ar.name = 'Nome da Regra'
      LIMIT 1
    ) THEN '✅ Mensagem após regra'
    ELSE '❌ Mensagem antes da regra'
  END as timing
FROM messages m
WHERE m.account_id = :account_id
  AND m.message_type IN (0, 1, 2)
  AND (
    LOWER(m.processed_message_content) LIKE '%palavra1%'
    OR LOWER(m.processed_message_content) LIKE '%palavra2%'
  )
  AND m.created_at >= '2025-11-01 00:00:00'
ORDER BY m.created_at DESC
LIMIT 100;
```

### Query: Apenas Mensagens que Deveriam Disparar

```sql
SELECT
  m.id,
  m.conversation_id,
  m.message_type,
  m.sender_type,
  m.content,
  m.created_at
FROM messages m
WHERE m.account_id = :account_id
  AND m.message_type IN (0, 1)  -- Não activity
  AND LOWER(m.processed_message_content) LIKE '%palavra1%'
  AND LOWER(m.processed_message_content) LIKE '%palavra2%'
  AND m.created_at >= (
    SELECT created_at
    FROM automation_rules
    WHERE name = 'Nome da Regra'
  )
ORDER BY m.created_at DESC;
```

## Arquivos de Referência

- [app/listeners/automation_rule_listener.rb](../../app/listeners/automation_rule_listener.rb)
- [app/services/automation_rules/conditions_filter_service.rb](../../app/services/automation_rules/conditions_filter_service.rb)
- [app/services/automation_rules/action_service.rb](../../app/services/automation_rules/action_service.rb)
- [app/models/automation_rule.rb](../../app/models/automation_rule.rb)
- [app/models/message.rb](../../app/models/message.rb)
- [app/builders/messages/message_builder.rb](../../app/builders/messages/message_builder.rb)
- [lib/tasks/debug_automation.rake](../../lib/tasks/debug_automation.rake)
- [docs/md/debugging_automation_rules.md](debugging_automation_rules.md)

## Conclusão

A investigação revelou que:

1. ✅ Sistema estava configurado corretamente
2. ✅ Mensagens continham as palavras-chave corretas
3. ✅ Mensagens não eram do tipo `activity`
4. ⚠️ **Provável causa**: Timing - automação criada depois das mensagens

**Lição aprendida**: Sempre verificar quando a automação foi criada vs quando as mensagens foram enviadas. Automações só funcionam em tempo real!

---

**Última atualização**: 2025-01-19
**Versão do Chatwoot**: 4.7.0+
**Caso investigado**: Account ID 71, Automação "Disparo revisão 12 meses"
