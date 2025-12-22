# fix_account_56_corrupted.rb
# Resolve conversas corrompidas na conta 56

CORRUPTED_IDS = [281760, 281761, 281762, 281764]

puts "=" * 80
puts "RESOLVENDO CONVERSAS CORROMPIDAS - ACCOUNT 56"
puts "=" * 80

puts "\nConversas a serem resolvidas:"
CORRUPTED_IDS.each do |id|
  conv = Conversation.find_by(id: id)
  if conv
    puts "  ##{conv.display_id} (ID: #{id}) - Status: #{conv.status}"
  else
    puts "  ID #{id} - NÃO ENCONTRADA"
  end
end

puts "\n" + "-" * 80
puts "Tem certeza que deseja resolver essas conversas? (y/n)"
print "> "

response = STDIN.gets.chomp.downcase

if response == 'y' || response == 'yes'
  puts "\n🔧 Resolvendo conversas..."

  count = Conversation.where(id: CORRUPTED_IDS).update_all(
    status: 1,  # resolved
    updated_at: Time.current
  )

  puts "✅ #{count} conversas resolvidas com sucesso!"

  # Verificar
  puts "\n📊 Verificação:"
  Conversation.where(id: CORRUPTED_IDS).each do |conv|
    puts "  ##{conv.display_id} - Status: #{conv.status} (#{conv.status == 'resolved' ? '✅' : '❌'})"
  end

else
  puts "\n❌ Operação cancelada"
end

puts "\n" + "=" * 80
puts "CONCLUÍDO"
puts "=" * 80
