# Feature: Auto-assign Agent on Reply

**Data:** 25 de Fevereiro de 2026
**Branch:** v4.7.0-custom
**Status:** Implementado - Pendente migration

---

## Problema

Quando um agente responde a uma conversa **sem responsavel (unassigned)**, nada acontecia em relacao a atribuicao. O agente precisava clicar manualmente em "Self-assign" ou alguem precisava atribui-lo. Isso era inconveniente — se o agente respondeu, ele ja esta cuidando daquela conversa.

## Solucao

Nova configuracao a nivel de **inbox** chamada `auto_assign_on_reply` (padrao: `true`) que, quando habilitada, atribui automaticamente o agente que respondeu como responsavel pela conversa.

### Comportamento

- Agente envia mensagem em conversa sem responsavel -> conversa e atribuida ao agente automaticamente
- Se a conversa ja tem responsavel -> nada muda
- Se a mensagem e nota privada -> nao atribui
- Se a mensagem veio de automacao/campanha -> nao atribui
- Se o setting esta desabilitado na inbox -> nao atribui

---

## Arquivos Modificados

| Arquivo | Acao |
|---|---|
| `db/migrate/20260225120000_add_auto_assign_on_reply_to_inboxes.rb` | **Criado** - Migration para adicionar coluna |
| `app/models/message.rb` | **Editado** - Metodo `auto_assign_agent_on_reply` + hook no callback |
| `app/controllers/api/v1/accounts/inboxes_controller.rb` | **Editado** - Parametro permitido na API |
| `app/views/api/v1/models/_inbox.json.jbuilder` | **Editado** - Campo na resposta da API |
| `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json` | **Editado** - Traducoes EN |
| `app/javascript/dashboard/i18n/locale/pt_BR/inboxMgmt.json` | **Editado** - Traducoes PT-BR |
| `app/javascript/dashboard/routes/.../CollaboratorsPage.vue` | **Editado** - Toggle na UI |

---

## Como Aplicar

### 1. Rodar a migration

```bash
# No WSL/terminal do servidor
cd /path/to/chatwoot
RAILS_ENV=production bundle exec rails db:migrate
```

Ou em desenvolvimento:

```bash
bundle exec rails db:migrate
```

### 2. Verificar que a coluna foi criada

```bash
bundle exec rails console
```

```ruby
Inbox.column_names.include?('auto_assign_on_reply')
# => true

# Verificar que todas as inboxes tem o default true
Inbox.where(auto_assign_on_reply: true).count
# Deve ser igual a Inbox.count
```

### 3. Reiniciar o servidor

```bash
# Se estiver usando systemd
sudo systemctl restart chatwoot.target

# Ou se estiver em dev
# Reiniciar o rails server e o webpack
```

---

## Configuracao na UI

1. Acesse **Settings > Inboxes > [sua inbox] > Collaborators**
2. Na secao **Conversation Assignment**, voce vera o novo toggle:
   - **"Auto-assign agent on reply"** / **"Atribuir agente automaticamente ao responder"**
3. O toggle vem **habilitado por padrao**
4. Desabilite se nao quiser esse comportamento para uma inbox especifica

---

## Logica do Backend (message.rb)

```ruby
def auto_assign_agent_on_reply
  return unless outgoing?                                    # Apenas msgs enviadas
  return unless sender.is_a?(User)                           # Apenas agentes humanos
  return if private?                                         # Ignora notas privadas
  return if content_attributes['automation_rule_id'].present? # Ignora automacoes
  return if additional_attributes['campaign_id'].present?     # Ignora campanhas
  return unless conversation.assignee_id.nil?                 # So se nao tem responsavel
  return unless inbox.auto_assign_on_reply                    # So se habilitado na inbox

  conversation.update!(assignee_id: sender_id)
end
```

O metodo e chamado em `execute_after_create_commit_callbacks`, logo apos `reopen_conversation` e antes de `set_conversation_activity`.

---

## Testes Manuais

1. **Teste basico:** Crie uma conversa sem responsavel, responda como agente -> conversa deve ser atribuida ao agente
2. **Setting desabilitado:** Desabilite o toggle na inbox, repita -> conversa NAO deve ser atribuida
3. **Nota privada:** Envie nota privada em conversa sem responsavel -> NAO deve atribuir
4. **Conversa ja atribuida:** Responda em conversa que ja tem responsavel -> responsavel NAO deve mudar
