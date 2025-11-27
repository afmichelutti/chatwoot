---
description: Debug de automações do Chatwoot que não estão disparando
---

# Debug Automation Rules

Este comando te ajuda a diagnosticar por que uma automação do Chatwoot não está disparando.

## 🎯 Objetivo

Identificar problemas em automações que deveriam ter sido executadas mas não foram.

---

## 📋 Informações Necessárias

Antes de começar, tenha em mãos:

1. **Nome da automação** ou parte do nome
2. **Texto da mensagem** que deveria disparar
3. **Data aproximada** da mensagem (ex: `2025-11-13`)
4. **Account ID** (geralmente: `1`)

---

## 🔍 Passo 1: Verificar se a Automação Existe

Execute no banco de dados:

```sql
SELECT
  ar.id,
  ar.name,
  ar.event_name,
  ar.active,
  ar.created_at as criada_em,
  ar.updated_at as atualizada_em,
  ar.conditions,
  ar.actions
FROM automation_rules ar
WHERE ar.account_id = 1  -- SEU ACCOUNT_ID
  AND (
    ar.name ILIKE '%TEXTO_DA_REGRA%'
    OR ar.name ILIKE '%palavra-chave%'
  )
ORDER BY ar.created_at DESC;
```

**Substitua:**
- `1` → seu account_id
- `TEXTO_DA_REGRA` → parte do nome da automação

**Verificar:**
- ✅ **active = true**: Automação está ativa
- ❌ **active = false**: Automação está desativada (não vai disparar!)

---

## 🔍 Passo 2: Buscar Mensagens que Deveriam Disparar

```sql
SELECT
  m.id,
  m.conversation_id,
  m.message_type,
  CASE
    WHEN m.message_type = 0 THEN 'incoming ⬇️ (aciona automação)'
    WHEN m.message_type = 1 THEN 'outgoing ⬆️ (aciona automação)'
    WHEN m.message_type = 2 THEN 'activity ❌ NUNCA ACIONA'
    WHEN m.message_type = 3 THEN 'template (aciona automação)'
  END as tipo,
  m.sender_type,
  m.content,
  m.processed_message_content,
  m.created_at
FROM messages m
WHERE m.account_id = 1  -- SEU ACCOUNT_ID
  AND LOWER(m.processed_message_content) LIKE '%palavra-chave%'
  AND m.created_at >= '2025-11-01 00:00:00'  -- DATA APROXIMADA
ORDER BY m.created_at DESC
LIMIT 50;
```

**Substitua:**
- `1` → seu account_id
- `palavra-chave` → texto que deveria disparar (ex: "revisão de 6 meses")
- `2025-11-01` → data aproximada das mensagens

**Verificar:**
- ✅ **message_type = 0 ou 1**: Deveria acionar automação
- ❌ **message_type = 2** (activity): **NUNCA aciona automação!**

---

## 🔍 Passo 3: Verificar Timing (Automação vs Mensagem)

**REGRA CRÍTICA:** Automações **NÃO são retroativas**. Só funcionam para mensagens **FUTURAS**.

```sql
SELECT
  m.id as message_id,
  m.conversation_id,
  m.content,
  m.created_at as mensagem_criada_em,
  (
    SELECT ar.created_at
    FROM automation_rules ar
    WHERE ar.name ILIKE '%TEXTO_DA_REGRA%'
      AND ar.account_id = 1
    LIMIT 1
  ) as regra_criada_em,
  CASE
    WHEN m.created_at >= (
      SELECT ar.created_at
      FROM automation_rules ar
      WHERE ar.name ILIKE '%TEXTO_DA_REGRA%'
        AND ar.account_id = 1
      LIMIT 1
    ) THEN '✅ Mensagem APÓS regra (deveria disparar)'
    ELSE '❌ Mensagem ANTES da regra (NÃO dispara - normal!)'
  END as timing_status
FROM messages m
WHERE m.account_id = 1
  AND m.message_type IN (0, 1)
  AND LOWER(m.processed_message_content) LIKE '%palavra-chave%'
  AND m.created_at >= '2025-11-01 00:00:00'
ORDER BY m.created_at DESC
LIMIT 50;
```

**Verificar:**
- ✅ **Mensagem APÓS regra**: Deveria ter disparado
- ❌ **Mensagem ANTES da regra**: Normal não disparar (retroatividade)

---

## 🔍 Passo 4: Query Completa de Diagnóstico

Esta query traz tudo junto:

```sql
SELECT
  m.id as message_id,
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
  CASE
    WHEN LOWER(m.processed_message_content) LIKE '%palavra-chave%' THEN 'SIM ✅'
    ELSE 'NÃO ❌'
  END as tem_palavra_chave,
  CASE
    WHEN m.message_type != 2
     AND LOWER(m.processed_message_content) LIKE '%palavra-chave%' THEN '🎯 DEVERIA DISPARAR'
    WHEN m.message_type = 2 THEN '❌ IGNORADO (activity)'
    ELSE '❌ NÃO ATENDE CONDIÇÕES'
  END as status_automacao,
  m.created_at as mensagem_em,
  c.status as conversation_status,
  ci.source_id as contact_phone,
  (
    SELECT COUNT(*)
    FROM automation_rules ar
    WHERE ar.account_id = m.account_id
      AND ar.active = true
      AND ar.event_name = 'message_created'
      AND ar.created_at <= m.created_at
      AND ar.name ILIKE '%TEXTO_DA_REGRA%'
  ) as regras_ativas_no_momento
FROM messages m
INNER JOIN conversations c ON c.id = m.conversation_id
INNER JOIN contact_inboxes ci ON ci.id = c.contact_inbox_id
WHERE m.account_id = 1
  AND LOWER(m.processed_message_content) LIKE '%palavra-chave%'
  AND m.created_at >= '2025-11-01 00:00:00'
ORDER BY m.created_at DESC
LIMIT 100;
```

**Análise da coluna `regras_ativas_no_momento`:**
- **0**: Nenhuma regra ativa no momento da mensagem (por isso não disparou!)
- **> 0**: Havia regra ativa, então deveria ter disparado

---

## 🔍 Passo 5: Verificar Condições da Automação

```sql
SELECT
  ar.id,
  ar.name,
  ar.event_name,
  ar.active,
  ar.conditions,
  jsonb_pretty(ar.conditions) as conditions_formatted
FROM automation_rules ar
WHERE ar.account_id = 1
  AND ar.name ILIKE '%TEXTO_DA_REGRA%';
```

**Verificar nas conditions:**
- `attribute_key`: Qual campo está sendo verificado?
- `filter_operator`: Qual operador? (`contains`, `equal_to`, etc.)
- `values`: Quais valores estão configurados?
- `query_operator`: `and` ou `or`?

**Exemplo de condição:**
```json
{
  "attribute_key": "message_content",
  "filter_operator": "contains",
  "values": ["revisão de 6 meses"],
  "query_operator": "and"
}
```

---

## ⚠️ Problemas Comuns

### ❌ Problema 1: Automação Inativa

**Sintoma:** `active = false`

**Solução:**
1. Ir para Settings → Automations
2. Encontrar a automação
3. Ativar o toggle

---

### ❌ Problema 2: Mensagens do Tipo Activity

**Sintoma:** `message_type = 2`

**Causa:** WhatsApp/WAHA está criando mensagens como `activity` em vez de `incoming`

**Solução:**
- Verificar configuração do WAHA
- Verificar canal do WhatsApp
- Mensagens `activity` **nunca** acionam automações (by design)

---

### ❌ Problema 3: Timing (Retroatividade)

**Sintoma:** Mensagem criada **ANTES** da automação

**Causa:** Automações não são retroativas

**Solução:**
- Normal! Automações só funcionam para mensagens **futuras**
- Se precisa processar mensagens antigas, precisa de script manual

---

### ❌ Problema 4: Condições Não Batem

**Sintoma:** Condições da automação não correspondem à mensagem

**Exemplos:**
- Automação busca "revisão 6 meses" mas mensagem tem "revisão de 6 meses"
- Case sensitive vs case insensitive
- Acentuação

**Solução:**
- Ajustar condições da automação para serem mais flexíveis
- Usar múltiplas condições com `OR`
- Usar `contains` em vez de `equal_to`

---

### ❌ Problema 5: Conversa Resolvida

**Sintoma:** `conversation_status = 'resolved'`

**Causa:** Algumas automações só funcionam em conversas abertas

**Verificar:**
```sql
SELECT
  m.id,
  m.content,
  c.status
FROM messages m
INNER JOIN conversations c ON c.id = m.conversation_id
WHERE m.id = 12345;  -- ID da mensagem
```

---

## 📊 Queries Adicionais Úteis

### Ver todas automações ativas
```sql
SELECT
  id,
  name,
  event_name,
  created_at
FROM automation_rules
WHERE account_id = 1
  AND active = true
  AND event_name = 'message_created'
ORDER BY created_at DESC;
```

### Ver últimas mensagens de uma conversa
```sql
SELECT
  m.id,
  m.message_type,
  m.content,
  m.created_at,
  u.email as sender
FROM messages m
LEFT JOIN users u ON u.id = m.sender_id
WHERE m.conversation_id = 12345  -- ID da conversa
ORDER BY m.created_at DESC
LIMIT 20;
```

### Ver execuções de automação (se houver log)
```sql
-- Verificar se há tabela de logs de automação
SELECT * FROM information_schema.tables
WHERE table_name LIKE '%automation%';
```

---

## 🛠️ Ferramentas de Debug

### Rails Console
```bash
bundle exec rails console
```

```ruby
# Buscar automação
ar = AutomationRule.find_by(name: 'Nome da Regra')
ar.conditions
ar.active?

# Testar condição manualmente
message = Message.find(12345)
# Ver conteúdo
message.processed_message_content

# Simular disparo (cuidado em produção!)
# AutomationRuleService.new(message).execute
```

---

## 📚 Documentação de Referência

Para mais detalhes sobre troubleshooting de automações:

- [docs/md/troubleshooting_automations_not_triggering.md](../docs/md/troubleshooting_automations_not_triggering.md)
- [docs/md/debugging_automation_rules.md](../docs/md/debugging_automation_rules.md)

---

## ✅ Checklist de Debug

Ao terminar o diagnóstico, você deve saber:

- [ ] A automação existe e está ativa?
- [ ] A mensagem é do tipo correto (não activity)?
- [ ] A mensagem foi criada **APÓS** a automação?
- [ ] As condições da automação batem com a mensagem?
- [ ] A conversa estava no estado correto?
- [ ] Não há outros filtros bloqueando?

---

**Se ainda não funcionar após verificar tudo acima, consulte a documentação completa ou peça ajuda com os resultados das queries!**
