# diagnose_500_error_account_56.rb
# Diagnóstico completo para erro 500 ao listar conversas

ACCOUNT_ID = ARGV[0]&.to_i || 56

puts "=" * 80
puts "DIAGNÓSTICO DE ERRO 500 - ACCOUNT #{ACCOUNT_ID}"
puts "=" * 80

account = Account.find(ACCOUNT_ID)

# Buscar conversas open/pending
conversations = account.conversations.where(status: [:open, :pending]).order(updated_at: :desc)

puts "\nTotal de conversas abertas/pendentes: #{conversations.count}"

# ===== FASE 1: Verificar relacionamentos órfãos =====
puts "\n" + "=" * 80
puts "FASE 1: Verificando relacionamentos órfãos"
puts "=" * 80

orphan_issues = {
  contact: [],
  inbox: [],
  contact_inbox: [],
  assignee: [],
  team: []
}

conversations.find_each.with_index do |conv, index|
  print "\rVerificando conversa #{index + 1}/#{conversations.count}..."

  # Verificar contact órfão
  if conv.contact_id.present? && conv.contact.nil?
    orphan_issues[:contact] << conv.id
  end

  # Verificar inbox órfão
  if conv.inbox_id.present? && conv.inbox.nil?
    orphan_issues[:inbox] << conv.id
  end

  # Verificar contact_inbox órfão
  if conv.contact_inbox_id.present? && conv.contact_inbox.nil?
    orphan_issues[:contact_inbox] << conv.id
  end

  # Verificar assignee órfão
  if conv.assignee_id.present? && conv.assignee.nil?
    orphan_issues[:assignee] << conv.id
  end

  # Verificar team órfão
  if conv.team_id.present? && conv.team.nil?
    orphan_issues[:team] << conv.id
  end
end

puts "\n"

# Mostrar resultados
orphan_issues.each do |type, ids|
  if ids.any?
    puts "❌ #{type.to_s.upcase} ÓRFÃO: #{ids.length} conversas"
    puts "   IDs: #{ids.first(10).join(', ')}#{ids.length > 10 ? '...' : ''}"
  else
    puts "✅ #{type.to_s.upcase}: OK"
  end
end

# ===== FASE 2: Tentar serializar cada conversa (simular API) =====
puts "\n" + "=" * 80
puts "FASE 2: Testando serialização (simulando endpoint da API)"
puts "=" * 80

serialization_errors = []

conversations.limit(50).find_each.with_index do |conv, index|
  print "\rTestando serialização #{index + 1}..."

  begin
    # Tentar acessar os mesmos campos que o serializer usa
    test_data = {
      id: conv.id,
      display_id: conv.display_id,
      status: conv.status,
      assignee_id: conv.assignee_id,
      contact_id: conv.contact_id,
      inbox_id: conv.inbox_id,

      # Testar relacionamentos
      contact: conv.contact&.id,
      inbox: conv.inbox&.id,
      contact_inbox: conv.contact_inbox&.id,

      # Testar métodos que podem causar erro
      unread_count: conv.unread_incoming_messages&.count,
      last_message: conv.messages&.last&.content,

      # Testar campos adicionais
      additional_attributes: conv.additional_attributes,
      custom_attributes: conv.custom_attributes,

      # Testar métodos de message.rb
      messages_test: conv.messages.limit(1).map { |msg|
        {
          id: msg.id,
          content: msg.content,
          # Este método pode causar erro se contact_inbox for nil
          push_event: msg.respond_to?(:conversation_push_event_data) ? msg.conversation_push_event_data : 'N/A'
        }
      }
    }

    print "✅"

  rescue => e
    print "❌"
    serialization_errors << {
      conversation_id: conv.id,
      display_id: conv.display_id,
      error: e.message,
      backtrace: e.backtrace.first(3)
    }
  end

  STDOUT.flush
end

puts "\n"

if serialization_errors.any?
  puts "\n❌ ERROS DE SERIALIZAÇÃO ENCONTRADOS: #{serialization_errors.length}"
  puts "\n" + "=" * 80

  serialization_errors.each_with_index do |err, idx|
    puts "\n#{idx + 1}. Conversa ##{err[:display_id]} (ID: #{err[:conversation_id]})"
    puts "   Erro: #{err[:error]}"
    puts "   Backtrace:"
    err[:backtrace].each { |line| puts "     #{line}" }
  end

  puts "\n" + "=" * 80
  puts "SOLUÇÃO SUGERIDA:"
  puts "=" * 80
  puts "Conversation.where(id: [#{serialization_errors.map { |e| e[:conversation_id] }.join(', ')}]).update_all(status: 1)"

else
  puts "✅ Nenhum erro de serialização encontrado nas primeiras 50 conversas"
end

# ===== FASE 3: Verificar mensagens órfãs =====
puts "\n" + "=" * 80
puts "FASE 3: Verificando mensagens com problemas"
puts "=" * 80

# Pegar conversas com mensagens recentes
recent_convs = conversations.limit(20)

message_issues = []

recent_convs.each do |conv|
  conv.messages.last(5).each do |msg|
    begin
      # Tentar acessar campos que podem causar erro
      msg.conversation_push_event_data if msg.respond_to?(:conversation_push_event_data)
      msg.sender
      msg.content_attributes
      msg.inbox
    rescue => e
      message_issues << {
        message_id: msg.id,
        conversation_id: conv.id,
        display_id: conv.display_id,
        error: e.message
      }
    end
  end
end

if message_issues.any?
  puts "❌ Problemas encontrados em #{message_issues.length} mensagens:"
  message_issues.first(10).each do |issue|
    puts "   Message #{issue[:message_id]} (Conv ##{issue[:display_id]}): #{issue[:error]}"
  end
else
  puts "✅ Nenhum problema encontrado em mensagens"
end

# ===== RESUMO FINAL =====
puts "\n" + "=" * 80
puts "RESUMO FINAL"
puts "=" * 80

total_issues = orphan_issues.values.flatten.uniq.length + serialization_errors.length

if total_issues > 0
  puts "❌ Total de conversas com problemas: #{total_issues}"
  puts "\nPróximos passos:"
  puts "1. Anote os IDs das conversas problemáticas acima"
  puts "2. Execute o comando de resolução sugerido"
  puts "3. Teste novamente o endpoint que estava dando erro 500"
else
  puts "✅ Nenhum problema óbvio encontrado!"
  puts "\nSugestões adicionais:"
  puts "1. Verificar logs do Rails em tempo real durante o erro"
  puts "2. Testar com mais conversas (aumentar o limit na FASE 2)"
  puts "3. Verificar se o erro ocorre em um endpoint específico"
end

puts "\n" + "=" * 80
puts "DIAGNÓSTICO CONCLUÍDO"
puts "=" * 80
