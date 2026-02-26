# delete_inbox_safe.rb
# Deleta uma inbox e TODAS as suas dependências de forma segura
# ATENÇÃO: Esta operação é IRREVERSÍVEL!

inbox_id = ARGV[0]&.to_i
force = ARGV[1] == '--force'

if inbox_id == 0
  puts "❌ Uso: bundle exec rails runner delete_inbox_safe.rb INBOX_ID [--force]"
  puts ""
  puts "Exemplos:"
  puts "  bundle exec rails runner delete_inbox_safe.rb 123          # Modo interativo"
  puts "  bundle exec rails runner delete_inbox_safe.rb 123 --force  # Deleta sem perguntar"
  exit 1
end

inbox = Inbox.find_by(id: inbox_id)

if inbox.nil?
  puts "❌ Inbox #{inbox_id} não encontrada"
  exit 1
end

puts "=" * 80
puts "DELEÇÃO DE INBOX - #{inbox.name.upcase}"
puts "=" * 80

puts "\n📥 Inbox: #{inbox.name} (ID: #{inbox_id})"
puts "   Account: #{inbox.account.name} (ID: #{inbox.account_id})"
puts "   Channel Type: #{inbox.channel_type}"

# Contar dependências
conversations_count = Conversation.where(inbox_id: inbox_id).count
messages_count = Message.joins(:conversation).where(conversations: { inbox_id: inbox_id }).count
contact_inboxes_count = ContactInbox.where(inbox_id: inbox_id).count
inbox_members_count = InboxMember.where(inbox_id: inbox_id).count

puts "\n⚠️  SERÁ DELETADO:"
puts "   - #{conversations_count} conversas"
puts "   - #{messages_count} mensagens"
puts "   - #{contact_inboxes_count} associações de contatos"
puts "   - #{inbox_members_count} associações de agentes"

# Confirmação
unless force
  puts "\n" + "=" * 80
  puts "⚠️  ATENÇÃO: ESTA OPERAÇÃO É IRREVERSÍVEL!"
  puts "=" * 80
  puts "\nTem certeza que deseja DELETAR esta inbox e todos os dados relacionados?"
  puts "Digite exatamente 'DELETAR #{inbox.name}' para confirmar:"
  print "> "

  response = STDIN.gets.chomp

  unless response == "DELETAR #{inbox.name}"
    puts "\n❌ Operação cancelada (confirmação incorreta)"
    exit 0
  end
end

puts "\n" + "=" * 80
puts "INICIANDO DELEÇÃO"
puts "=" * 80

# Usar transação para garantir atomicidade
ActiveRecord::Base.transaction do

  # 1. Deletar mensagens (em lotes para evitar timeout)
  if messages_count > 0
    puts "\n1️⃣ Deletando #{messages_count} mensagens..."
    conversation_ids = Conversation.where(inbox_id: inbox_id).pluck(:id)

    deleted = 0
    conversation_ids.each_slice(100) do |batch|
      count = Message.where(conversation_id: batch).delete_all
      deleted += count
      print "\r   Deletadas: #{deleted}/#{messages_count}"
      STDOUT.flush
    end
    puts " ✅"
  end

  # 2. Deletar conversas (em lotes)
  if conversations_count > 0
    puts "\n2️⃣ Deletando #{conversations_count} conversas..."
    deleted = 0
    Conversation.where(inbox_id: inbox_id).find_in_batches(batch_size: 100) do |batch|
      batch.each(&:destroy)
      deleted += batch.size
      print "\r   Deletadas: #{deleted}/#{conversations_count}"
      STDOUT.flush
    end
    puts " ✅"
  end

  # 3. Deletar ContactInboxes
  if contact_inboxes_count > 0
    puts "\n3️⃣ Deletando #{contact_inboxes_count} contact_inboxes..."
    ContactInbox.where(inbox_id: inbox_id).delete_all
    puts "   ✅"
  end

  # 4. Deletar InboxMembers
  if inbox_members_count > 0
    puts "\n4️⃣ Deletando #{inbox_members_count} inbox_members..."
    InboxMember.where(inbox_id: inbox_id).delete_all
    puts "   ✅"
  end

  # 5. Deletar TeamInboxes (se existir)
  begin
    team_inboxes_count = TeamInbox.where(inbox_id: inbox_id).count
    if team_inboxes_count > 0
      puts "\n5️⃣ Deletando #{team_inboxes_count} team_inboxes..."
      TeamInbox.where(inbox_id: inbox_id).delete_all
      puts "   ✅"
    end
  rescue
    # Tabela pode não existir em versões antigas
  end

  # 6. Deletar Webhooks (se existir)
  begin
    webhooks_count = Webhook.where(inbox_id: inbox_id).count
    if webhooks_count > 0
      puts "\n6️⃣ Deletando #{webhooks_count} webhooks..."
      Webhook.where(inbox_id: inbox_id).delete_all
      puts "   ✅"
    end
  rescue
    # Modelo pode não existir
  end

  # 7. Deletar Channel
  puts "\n7️⃣ Deletando channel (#{inbox.channel_type})..."
  begin
    channel = inbox.channel
    channel&.destroy
    puts "   ✅"
  rescue => e
    puts "   ⚠️  Erro ao deletar channel: #{e.message}"
  end

  # 8. Finalmente, deletar a Inbox
  puts "\n8️⃣ Deletando inbox..."
  inbox.destroy
  puts "   ✅"

  puts "\n" + "=" * 80
  puts "✅ INBOX DELETADA COM SUCESSO!"
  puts "=" * 80

  puts "\nResumo:"
  puts "   - #{messages_count} mensagens deletadas"
  puts "   - #{conversations_count} conversas deletadas"
  puts "   - #{contact_inboxes_count} contact_inboxes deletados"
  puts "   - #{inbox_members_count} inbox_members deletados"
  puts "   - Inbox '#{inbox.name}' deletada"

rescue => e
  puts "\n" + "=" * 80
  puts "❌ ERRO DURANTE DELEÇÃO"
  puts "=" * 80
  puts "Erro: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.first(5).join("\n")
  puts "\n⚠️  A transação foi revertida. Nenhum dado foi deletado."
  raise
end

puts "\n" + "=" * 80
puts "DELEÇÃO CONCLUÍDA"
puts "=" * 80
