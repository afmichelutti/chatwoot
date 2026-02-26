# diagnose_inbox_dependencies.rb
# Diagnostica todas as dependências de uma inbox antes de deletar

inbox_id = ARGV[0]&.to_i

if inbox_id == 0
  puts "❌ Uso: bundle exec rails runner diagnose_inbox_dependencies.rb INBOX_ID"
  exit 1
end

inbox = Inbox.find_by(id: inbox_id)

if inbox.nil?
  puts "❌ Inbox #{inbox_id} não encontrada"
  exit 1
end

puts "=" * 80
puts "DIAGNÓSTICO DE DEPENDÊNCIAS - INBOX ##{inbox_id}"
puts "=" * 80

puts "\n📥 Inbox: #{inbox.name} (ID: #{inbox_id})"
puts "   Account: #{inbox.account.name} (ID: #{inbox.account_id})"
puts "   Channel Type: #{inbox.channel_type}"
puts "   Criada em: #{inbox.created_at}"

puts "\n" + "=" * 80
puts "DEPENDÊNCIAS ENCONTRADAS"
puts "=" * 80

# 1. Conversas
conversations_count = Conversation.where(inbox_id: inbox_id).count
puts "\n1️⃣ CONVERSAS: #{conversations_count}"
if conversations_count > 0
  puts "   - Abertas/Pendentes: #{Conversation.where(inbox_id: inbox_id, status: [:open, :pending]).count}"
  puts "   - Resolvidas: #{Conversation.where(inbox_id: inbox_id, status: :resolved).count}"
  puts "   - Snoozed: #{Conversation.where(inbox_id: inbox_id, status: :snoozed).count}"
end

# 2. Mensagens (via conversas)
messages_count = Message.joins(:conversation).where(conversations: { inbox_id: inbox_id }).count
puts "\n2️⃣ MENSAGENS: #{messages_count}"

# 3. ContactInboxes
contact_inboxes_count = ContactInbox.where(inbox_id: inbox_id).count
puts "\n3️⃣ CONTACT_INBOXES: #{contact_inboxes_count}"

# 4. InboxMembers (agentes)
inbox_members_count = InboxMember.where(inbox_id: inbox_id).count
puts "\n4️⃣ INBOX_MEMBERS (Agentes): #{inbox_members_count}"
if inbox_members_count > 0
  InboxMember.where(inbox_id: inbox_id).each do |im|
    user = User.find(im.user_id)
    puts "   - #{user.name} (#{user.email})"
  end
end

# 5. Webhooks
webhooks_count = Webhook.where(inbox_id: inbox_id).count rescue 0
puts "\n5️⃣ WEBHOOKS: #{webhooks_count}"

# 6. Canned Responses
canned_responses_count = CannedResponse.where(account_id: inbox.account_id).count rescue 0
puts "\n6️⃣ CANNED_RESPONSES (conta toda): #{canned_responses_count}"

# 7. Teams associados
teams_count = inbox.respond_to?(:team_inboxes) ? TeamInbox.where(inbox_id: inbox_id).count : 0
puts "\n7️⃣ TEAMS ASSOCIADOS: #{teams_count}"

# 8. Channel (canal da inbox)
puts "\n8️⃣ CHANNEL:"
puts "   - Type: #{inbox.channel_type}"
puts "   - ID: #{inbox.channel_id}"

# 9. Automation Rules que usam essa inbox
automation_rules_count = AutomationRule.where(account_id: inbox.account_id)
                                       .where("conditions::text LIKE ?", "%inbox_id%#{inbox_id}%")
                                       .count rescue 0
puts "\n9️⃣ AUTOMATION RULES (que podem usar essa inbox): #{automation_rules_count}"

puts "\n" + "=" * 80
puts "ESTIMATIVA DE TEMPO DE DELEÇÃO"
puts "=" * 80

total_records = conversations_count + messages_count + contact_inboxes_count + inbox_members_count

if total_records < 100
  puts "⚡ RÁPIDO: ~1-2 minutos"
elsif total_records < 1000
  puts "⏱️  MÉDIO: ~5-10 minutos"
elsif total_records < 10000
  puts "🕐 LENTO: ~30-60 minutos"
else
  puts "🕐 MUITO LENTO: Pode levar HORAS"
end

puts "\n⚠️  ATENÇÃO:"
puts "   - Esta operação é IRREVERSÍVEL"
puts "   - Todas as conversas e mensagens serão DELETADAS"
puts "   - Contatos NÃO serão deletados (apenas a associação)"

puts "\n" + "=" * 80
puts "PRÓXIMOS PASSOS"
puts "=" * 80
puts "\nPara deletar esta inbox, execute:"
puts "  bundle exec rails runner delete_inbox_safe.rb #{inbox_id}"

puts "\n" + "=" * 80
puts "DIAGNÓSTICO CONCLUÍDO"
puts "=" * 80
