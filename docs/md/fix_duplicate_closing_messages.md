# Fix: Mensagens de Encerramento Duplicadas (Triplicadas)

**Data:** 2025-11-27
**Problema:** Sistema enviando 3 mensagens de encerramento idênticas ao finalizar atendimento
**Causa:** Automation rules redundantes disparando simultaneamente

---

## 🔍 Análise do Problema

Identificamos **3 automation rules** enviando a mesma mensagem de encerramento:

### ❌ Regras duplicadas/triplicadas:

#### 1. **Rule ID 11** - `encerra_autoatendimento`

- **Event:** `message_created`
- **Conditions:**
  - content contains "atendimento" AND
  - content contains "finalizado" AND
  - content contains "sucesso" AND
  - content contains "autoatendimento" AND
  - inbox_id = 3
- **Actions:**
  - `resolve_conversation`
  - `send_message`: "Atendimento finalizado! 🤗 Agradecemos seu contato!..."
- **Status:** ✅ ACTIVE

#### 2. **Rule ID 14** - `encerra_atendimento`

- **Event:** `message_created`
- **Conditions:**
  - content contains "atendimento" AND
  - content contains "finalizado" AND
  - content contains "sucesso"
- **Actions:**
  - `resolve_conversation`
  - `send_message`: "Atendimento finalizado! 🤗 Agradecemos seu contato!..." (**MESMA MENSAGEM**)
- **Status:** ✅ ACTIVE

#### 3. **Rule ID 3** - `encerramento`

- **Event:** `conversation_updated`
- **Conditions:**
  - status = "resolved" AND
  - inbox_id = 3
- **Actions:**
  - `send_message`: "Atendimento finalizado! 🤗 Agradecemos seu contato!..." (**MESMA MENSAGEM**)
- **Status:** ✅ ACTIVE

---

## 🐛 O que está acontecendo (ciclo vicioso):

1. **Autoatendimento envia mensagem:** "atendimento finalizado com sucesso autoatendimento"

2. **Rule 11** (`encerra_autoatendimento`) dispara:

   - ✅ Matches: "atendimento", "finalizado", "sucesso", "autoatendimento"
   - Ação: `resolve_conversation` + `send_message`
   - Resultado: Conversa marcada como "resolved" + **1ª mensagem enviada**

3. **Rule 14** (`encerra_atendimento`) TAMBÉM dispara (menos específica):

   - ✅ Matches: "atendimento", "finalizado", "sucesso"
   - Ação: `resolve_conversation` + `send_message`
   - Resultado: **2ª mensagem enviada**

4. **Rule 3** (`encerramento`) dispara porque a conversa foi marcada como "resolved":
   - ✅ Conversa agora está "resolved" + inbox_id = 3
   - Ação: `send_message`
   - Resultado: **3ª mensagem enviada**

---

## ✅ Solução: Desativar regras redundantes

### Opção 1: Manter apenas a Rule 3 (✅ Recomendada)

Desative as **Rule 11 e Rule 14** e deixe apenas a **Rule 3** (`encerramento`), que dispara quando a conversa é marcada como "resolved".

**No Rails Console do Portainer:**

```ruby
# Desativar Rule 11 (encerra_autoatendimento)
AutomationRule.find(11).update!(active: false)

# Desativar Rule 14 (encerra_atendimento)
AutomationRule.find(14).update!(active: false)

# Verificar
AutomationRule.where(id: [3, 11, 14]).pluck(:id, :name, :active)
# Deve retornar:
# [[3, "encerramento", true], [11, "encerra_autoatendimento", false], [14, "encerra_atendimento", false]]
```

**Resultado:**

- Quando o autoatendimento enviar a mensagem com "finalizado com sucesso", ele deve marcar a conversa como "resolved" por conta própria
- A Rule 3 vai disparar e enviar **UMA única mensagem** de encerramento

---

### Opção 2: Remover action `send_message` das Rules 11 e 14

Se você precisa que as Rules 11 e 14 marquem a conversa como "resolved", remova apenas a action `send_message` delas.

**No Rails Console:**

```ruby
# Rule 11: Remover send_message, manter apenas resolve_conversation
rule11 = AutomationRule.find(11)
rule11.update!(actions: [{action_name: "resolve_conversation", action_params: []}].to_json)

# Rule 14: Remover send_message, manter apenas resolve_conversation
rule14 = AutomationRule.find(14)
rule14.update!(actions: [{action_name: "resolve_conversation", action_params: []}].to_json)

# Verificar
[11, 14].each do |id|
  rule = AutomationRule.find(id)
  puts "Rule #{id}: #{JSON.parse(rule.actions)}"
end
```

**Resultado:**

- Rules 11 e 14 apenas marcam a conversa como "resolved"
- Rule 3 envia a mensagem de encerramento (uma única vez)

---

## 🎯 Recomendação Final

**Use a Opção 1** (desativar Rules 11 e 14) porque:

1. ✅ Você já tem a Rule 3 que faz o trabalho de enviar a mensagem quando a conversa é resolvida
2. ✅ Reduz redundância e complexidade
3. ✅ Evita loops infinitos
4. ✅ Mais fácil de manter e debugar

---

## 📋 Checklist de Execução

- [ ] Acessar console do container no Portainer
- [ ] Executar `bundle exec rails console`
- [ ] Desativar Rule 11: `AutomationRule.find(11).update!(active: false)`
- [ ] Desativar Rule 14: `AutomationRule.find(14).update!(active: false)`
- [ ] Verificar: `AutomationRule.where(id: [3, 11, 14]).pluck(:id, :name, :active)`
- [ ] Testar com atendimento real
- [ ] Confirmar que apenas 1 mensagem de encerramento é enviada

---

## 🔧 Rollback (caso necessário)

Se precisar reverter as mudanças:

```ruby
# Reativar Rule 11
AutomationRule.find(11).update!(active: true)

# Reativar Rule 14
AutomationRule.find(14).update!(active: true)

# Verificar
AutomationRule.where(id: [11, 14]).pluck(:id, :name, :active)
```

---

## 📊 Evidências do Problema

![Mensagens triplicadas](../screenshots/duplicate_closing_messages.png)

**Timestamp das mensagens:**

- Nov 27, 3:26 PM - Primeira mensagem
- Nov 27, 3:26 PM - Segunda mensagem (duplicata)
- Nov 27, 3:26 PM - Terceira mensagem (triplicata)

Todas enviadas no mesmo segundo, confirmando que são disparadas por automation rules simultâneas.

---

## 📝 Notas Adicionais

- Este problema só afeta conversas no **inbox_id = 3** (autoatendimento)
- As outras regras de encerramento (Rules 11 e 14) foram criadas antes da Rule 3 genérica
- A Rule 3 é mais genérica e cobre todos os casos de encerramento para o inbox 3
- Manter regras redundantes pode causar problemas futuros de manutenção
