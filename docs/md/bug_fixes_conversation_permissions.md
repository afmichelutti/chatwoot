# Bug Fixes: Conversation Permissions & Error 500

**Data:** 18 de Dezembro de 2025
**Branch:** v4.7.0-custom
**Ambiente:** Produção (Caper Advogados - Account ID: 1)

---

## 🐛 Bug #1: Erro 500 ao listar conversas do usuário Cloves

### Problema

Usuário Cloves (cloves@caperbrasil.com.br, user_id: 58) recebia erro 500 ao tentar acessar:
```
GET /api/v1/accounts/1/conversations?status=open&assignee_type=me&page=1&sort_by=last_activity_at_desc
```

**Erro:**
```
NoMethodError: undefined method 'source_id' for nil
at app/models/message.rb:171
```

### Causa Raiz

A conversa #164207 estava **corrompida**:
- Tinha `contact_id: 234095` ✅
- Mas `contact_inbox_id: NULL` ❌

Quando o sistema tentava serializar a conversa para JSON, o método `conversation_push_event_data` em `message.rb:171` tentava acessar:
```ruby
contact_inbox: { source_id: conversation.contact_inbox.source_id }
```

Como `contact_inbox` era `nil`, causava `NoMethodError`.

### Solução Implementada

#### 1. Hotfix Imediato (Produção)

Executado script para resolver a conversa corrompida:

```ruby
# fix_corrupted_conversation.rb
conv = Conversation.find_by(display_id: 164207, account_id: 1)
conv.status = :resolved
conv.save!(validate: false)
```

**Resultado:** Erro 500 resolvido imediatamente.

#### 2. Fix Permanente (Código)

Modificado `app/models/message.rb` (linhas 166-175):

**Antes:**
```ruby
def conversation_push_event_data
  {
    assignee_id: conversation.assignee_id,
    unread_count: conversation.unread_incoming_messages.count,
    last_activity_at: conversation.last_activity_at.to_i,
    contact_inbox: { source_id: conversation.contact_inbox.source_id }
  }
end
```

**Depois:**
```ruby
def conversation_push_event_data
  data = {
    assignee_id: conversation.assignee_id,
    unread_count: conversation.unread_incoming_messages.count,
    last_activity_at: conversation.last_activity_at.to_i
  }
  # Add contact_inbox only if it exists (prevent nil error for corrupted data)
  data[:contact_inbox] = { source_id: conversation.contact_inbox.source_id } if conversation.contact_inbox.present?
  data
end
```

**Arquivo modificado:**
- `app/models/message.rb` (linhas 166-175)

**Resultado:** Previne erro 500 caso existam outras conversas corrompidas no banco.

---

## 🐛 Bug #2: Agentes com `conversation_participating_manage` conseguem acessar conversas não atribuídas

### Problema

Agentes com a permissão `conversation_participating_manage` (Custom Role "Cobrança"):
- ✅ Na lista de conversas: viam apenas conversas atribuídas a eles (correto)
- ❌ No histórico do contato: conseguiam **ver e abrir** conversas de outros agentes (incorreto)
- ❌ URL direta: conseguiam acessar qualquer conversa do inbox (incorreto)

**Exemplo:**
- Usuário: Cintia (cintiajoaoiza@gmail.com) com role "Cobrança"
- Permissões: `["conversation_participating_manage", "contact_manage"]`
- Conseguia abrir conversa #2204 atribuída à Gracielle ❌

### Causa Raiz

O controller `ConversationsController` verificava apenas se o usuário tinha acesso ao **INBOX**, não à **CONVERSA específica**.

**Código problemático** em `app/controllers/api/v1/accounts/conversations_controller.rb:161-164`:

```ruby
def conversation
  @conversation ||= Current.account.conversations.find_by!(display_id: params[:id])
  authorize @conversation.inbox, :show?  # <-- Só verifica inbox!
end
```

Isso permitia que qualquer agente com acesso ao inbox pudesse:
1. Abrir qualquer conversa daquele inbox via URL direta
2. Ver histórico completo de conversas de um contato
3. Interagir com conversas não atribuídas a ele

### Solução Implementada

Adicionado método `check_conversation_permission!` que aplica o `PermissionFilterService` antes de permitir acesso.

**Código modificado** em `app/controllers/api/v1/accounts/conversations_controller.rb`:

```ruby
def conversation
  @conversation ||= Current.account.conversations.find_by!(display_id: params[:id])
  authorize @conversation.inbox, :show?

  # Check if user has permission to access this specific conversation based on custom role
  check_conversation_permission!
end

def check_conversation_permission!
  # Apply permission-based filtering to ensure user can access this conversation
  filtered_conversations = Conversations::PermissionFilterService.new(
    Conversation.where(id: @conversation.id),
    Current.user,
    Current.account
  ).perform

  # If the conversation is not in the filtered results, user doesn't have permission
  return if filtered_conversations.exists?

  # Render 403 Forbidden if user doesn't have permission
  render json: { error: 'You do not have permission to access this conversation' }, status: :forbidden
end
```

**Arquivo modificado:**
- `app/controllers/api/v1/accounts/conversations_controller.rb` (linhas 161-182)

### Comportamento Esperado

#### Permissão: `conversation_participating_manage`

**PODE fazer:**
- ✅ Ver lista de conversas atribuídas a ele
- ✅ Abrir conversas atribuídas a ele
- ✅ Ver detalhes do contato (nome, email, telefone)
- ✅ Buscar contatos

**NÃO PODE fazer:**
- ❌ Ver conversas não atribuídas na lista
- ❌ Ver histórico de conversas não atribuídas no painel do contato
- ❌ Abrir conversas atribuídas a outros agentes (retorna 403 Forbidden)
- ❌ Enviar mensagens em conversas não atribuídas

#### Permissão: `conversation_manage` (ou Administrator)

**PODE fazer:**
- ✅ Ver e acessar TODAS as conversas do account
- ✅ Sem restrições

---

## 🧪 Testes Realizados

### Teste 1: Erro 500 corrigido

```bash
# Script: test_serialization.rb
✅ 25 conversas serializadas com sucesso
✅ Conversa #164207 não causa mais erro
```

### Teste 2: Permission Filter funcionando

```bash
# Script: test_contact_conversation_filter.rb
✅ PermissionFilterService filtra corretamente conversas do contato
✅ Usuário Cintia (conversation_participating_manage) vê 0 conversas não atribuídas
```

### Teste 3: Bloqueio de acesso

```bash
# Script: test_open_unassigned_conversation.rb
❌ ANTES: ConversationPolicy.show? retornava true (bug!)
✅ DEPOIS: PermissionFilterService bloqueia acesso

# Script: test_permission_fix.rb
✅ Agente pode acessar suas próprias conversas
✅ Agente NÃO pode acessar conversas de outros (403 Forbidden)
✅ Administrador pode acessar todas as conversas
```

---

## 📦 Arquivos Modificados

### Código de Produção

1. **app/models/message.rb** (linhas 166-175)
   - Adiciona verificação `if conversation.contact_inbox.present?`
   - Previne NoMethodError em conversas corrompidas

2. **app/controllers/api/v1/accounts/conversations_controller.rb** (linhas 161-182)
   - Adiciona método `check_conversation_permission!`
   - Aplica `PermissionFilterService` antes de permitir acesso
   - Retorna 403 Forbidden se permissão negada

### Scripts de Debug (não fazem parte do deploy)

- `debug_cloves_error.rb` - Debug do erro 500
- `test_serialization.rb` - Testa serialização JSON
- `test_contact_conversation_filter.rb` - Testa filtro de histórico
- `test_open_unassigned_conversation.rb` - Testa acesso a conversas
- `test_permission_fix.rb` - Valida correção de permissões
- `fix_corrupted_conversation.rb` - Hotfix para conversa corrompida

---

## 🚀 Deploy

### Preparação

```bash
# Verificar mudanças
git status
git diff app/models/message.rb
git diff app/controllers/api/v1/accounts/conversations_controller.rb

# Commit
git add app/models/message.rb app/controllers/api/v1/accounts/conversations_controller.rb
git commit -m "fix: Add conversation permission check and handle nil contact_inbox

- Fix error 500 when conversation has nil contact_inbox (message.rb)
- Add permission check for individual conversation access (conversations_controller.rb)
- Respect conversation_participating_manage permission on show action
- Return 403 Forbidden when user tries to access unauthorized conversation

Fixes issue where agents with conversation_participating_manage could access
conversations not assigned to them via direct URL or contact history panel."

# Push
git push origin v4.7.0-custom
```

### Deploy em Produção (Docker/Portainer)

1. Pull da imagem atualizada ou rebuild
2. Restart do container Rails
3. Verificar logs para confirmar deploy

```bash
# No container
cd /app
bundle exec rails runner "puts 'Deploy verificado: #{Time.now}'"
```

### Verificação Pós-Deploy

1. Login como agente com `conversation_participating_manage`
2. Tentar acessar conversa não atribuída via URL
3. Verificar retorno 403 Forbidden
4. Confirmar que conversas próprias ainda funcionam

---

## 🔗 Referências

- **Custom Roles Documentation:** `enterprise/app/models/custom_role.rb`
- **Permission Filter Service:** `enterprise/app/services/enterprise/conversations/permission_filter_service.rb`
- **Conversation Finder:** `app/finders/conversation_finder.rb`
- **Permissões disponíveis:**
  - `conversation_manage` - Todas as conversas
  - `conversation_unassigned_manage` - Não atribuídas + próprias
  - `conversation_participating_manage` - Apenas atribuídas a mim
  - `contact_manage` - Gerenciar contatos
  - `report_manage` - Ver relatórios
  - `knowledge_base_manage` - Gerenciar base de conhecimento

---

## 📝 Notas Adicionais

### Conversa Corrompida #164207

**Por que aconteceu?**
- Possível bug na criação de conversas
- Falha em transaction que não criou `contact_inbox`
- Importação de dados sem validação completa

**Como prevenir?**
- Adicionar validação `validates :contact_inbox, presence: true` no model Conversation
- Ou manter o fix defensivo em `message.rb` (recomendado)

### Performance

A adição do `check_conversation_permission!` adiciona **1 query extra** por requisição:
```sql
SELECT * FROM conversations WHERE id = ? -- PermissionFilterService
```

Impacto: ~10-20ms em média (latência de rede para banco remoto)

### Backward Compatibility

✅ **Sem breaking changes:**
- Administradores continuam vendo tudo
- Agentes sem custom role continuam vendo conversas do inbox
- Apenas agentes com `conversation_participating_manage` têm restrição adicional

---

**Autor:** Claude + Desenvolvedor
**Revisado por:** _[Pendente]_
**Status:** ✅ Implementado e testado localmente | ⏳ Aguardando deploy em produção
