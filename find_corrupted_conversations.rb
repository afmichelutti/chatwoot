# find_corrupted_conversations.rb
# Encontra TODAS as conversas corrompidas em uma conta (verifica TODOS os relacionamentos)
# Atualizado em 2025-12-19 para incluir todos os tipos de corrupção

account_id = ARGV[0]&.to_i || 1

puts "=" * 80
puts "BUSCANDO CONVERSAS CORROMPIDAS - ACCOUNT #{account_id}"
puts "=" * 80

account = Account.find(account_id)

# Buscar conversas open/pending
conversations = account.conversations.where(status: [:open, :pending])

puts "\nTotal de conversas abertas/pendentes: #{conversations.count}"
puts "\n" + "=" * 80
puts "VERIFICANDO INTEGRIDADE (TODOS OS RELACIONAMENTOS)"
puts "=" * 80

corrupted = []
orphan_types = {
  contact: [],
  inbox: [],
  contact_inbox: [],
  assignee: [],
  team: []
}

conversations.find_each.with_index do |conv, index|
  print "\rVerificando #{index + 1}/#{conversations.count}..."

  issues = []

  # Verificar contact órfão
  if conv.contact_id.present? && conv.contact.nil?
    issues << 'contact'
    orphan_types[:contact] << conv.id
  end

  # Verificar inbox órfão
  if conv.inbox_id.present? && conv.inbox.nil?
    issues << 'inbox'
    orphan_types[:inbox] << conv.id
  end

  # Verificar contact_inbox órfão
  if conv.contact_inbox_id.present? && conv.contact_inbox.nil?
    issues << 'contact_inbox'
    orphan_types[:contact_inbox] << conv.id
  end

  # Verificar assignee órfão
  if conv.assignee_id.present? && conv.assignee.nil?
    issues << 'assignee'
    orphan_types[:assignee] << conv.id
  end

  # Verificar team órfão
  if conv.team_id.present? && conv.team.nil?
    issues << 'team'
    orphan_types[:team] << conv.id
  end

  if issues.any?
    corrupted << {
      id: conv.id,
      display_id: conv.display_id,
      status: conv.status,
      issues: issues
    }
    print " ❌"
  else
    print " ✅"
  end

  STDOUT.flush
end

puts "\n\n" + "=" * 80
puts "RESULTADO"
puts "=" * 80
puts "Conversas verificadas: #{conversations.count}"
puts "Conversas corrompidas: #{corrupted.length}"

if corrupted.any?
  # Mostrar estatísticas por tipo
  puts "\n" + "-" * 80
  puts "TIPOS DE CORRUPÇÃO ENCONTRADOS"
  puts "-" * 80
  orphan_types.each do |type, ids|
    next if ids.empty?
    emoji = case type
            when :contact, :inbox, :contact_inbox then "🔴"
            when :assignee, :team then "🟡"
            else "⚪"
            end
    puts "  #{emoji} #{type.to_s.upcase.ljust(20)} : #{ids.length} conversas"
  end

  puts "\n" + "-" * 80
  puts "CONVERSAS CORROMPIDAS DETALHADAS"
  puts "-" * 80
  corrupted.each do |c|
    puts "  ##{c[:display_id].to_s.ljust(10)} (ID: #{c[:id].to_s.ljust(8)}) - Problemas: #{c[:issues].join(', ')}"
  end

  puts "\n" + "=" * 80
  puts "COMANDO PARA RESOLVER"
  puts "=" * 80
  puts "Conversation.where(id: [#{corrupted.map { |c| c[:id] }.join(', ')}]).update_all(status: 1)"

  puts "\n" + "=" * 80
  puts "SQL PARA RESOLVER"
  puts "=" * 80
  puts "UPDATE conversations SET status = 1, updated_at = NOW() WHERE id IN (#{corrupted.map { |c| c[:id] }.join(', ')});"

else
  puts "\n✅ NENHUMA CONVERSA CORROMPIDA ENCONTRADA!"
  puts "\nTodas as conversas estão íntegras nesta conta."
end

puts "\n" + "=" * 80
puts "DIAGNÓSTICO CONCLUÍDO"
puts "=" * 80
