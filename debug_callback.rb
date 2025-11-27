# Debug script para verificar por que o callback não está sendo executado
puts "=" * 80
puts "DEBUG: ACTIVITY-BASED PRESENCE CALLBACK"
puts "=" * 80

account_id = 1
user_id = 1

puts "\n📋 VERIFICANDO CONDIÇÕES DO CALLBACK..."

# Simular a última mensagem enviada
last_message = Message.where(
  account_id: account_id,
  sender_id: user_id,
  sender_type: 'User'
).reorder('created_at DESC').limit(1).first

if last_message.nil?
  puts "\n❌ NENHUMA MENSAGEM ENCONTRADA!"
  puts "   O usuário #{user_id} nunca enviou mensagens?"
  exit
end

puts "\n📨 ÚLTIMA MENSAGEM:"
puts "  ID: #{last_message.id}"
puts "  Created: #{last_message.created_at}"
puts "  Sender Type: #{last_message.sender_type}"
puts "  Sender ID: #{last_message.sender_id}"
puts "  Message Type: #{last_message.message_type}"

# Verificar cada condição do callback
puts "\n🔍 VERIFICANDO CONDIÇÕES (na ordem que o callback verifica):"

# Condição 1: sender_type == 'User'
check1 = last_message.sender_type == 'User'
puts "\n  1️⃣ sender_type == 'User'?"
puts "     Valor atual: '#{last_message.sender_type}'"
puts "     Resultado: #{check1 ? '✅ PASSOU' : '❌ FALHOU'}"

# Condição 2: sender_id.present?
check2 = last_message.sender_id.present?
puts "\n  2️⃣ sender_id.present??"
puts "     Valor atual: #{last_message.sender_id.inspect}"
puts "     Resultado: #{check2 ? '✅ PASSOU' : '❌ FALHOU'}"

# Condição 3: account.activity_based_presence_enabled?
account = Account.find(account_id)
check3 = account.activity_based_presence_enabled?
puts "\n  3️⃣ account.activity_based_presence_enabled??"
puts "     Valor atual: #{account.activity_based_presence_enabled}"
puts "     Resultado: #{check3 ? '✅ PASSOU' : '❌ FALHOU'}"

# Condição 4: AccountUser existe?
account_user = AccountUser.find_by(account_id: account_id, user_id: last_message.sender_id)
check4 = account_user.present?
puts "\n  4️⃣ AccountUser encontrado??"
puts "     Valor atual: #{account_user.inspect}"
puts "     Resultado: #{check4 ? '✅ PASSOU' : '❌ FALHOU'}"

if account_user.nil?
  puts "\n❌ PROBLEMA ENCONTRADO: AccountUser não existe!"
  puts "   Isso significa que o user_id #{last_message.sender_id} não está associado à conta #{account_id}"
  exit
end

# Condição 5: auto_offline deve ser FALSE
check5 = !account_user.auto_offline?
puts "\n  5️⃣ auto_offline == false? (se TRUE, callback não roda)"
puts "     Valor atual: auto_offline=#{account_user.auto_offline}"
puts "     Resultado: #{check5 ? '✅ PASSOU (auto_offline=false)' : '❌ FALHOU (auto_offline=true, callback IGNORADO)'}"

# Condição 6: availability != 'busy'
check6 = account_user.availability != 'busy'
puts "\n  6️⃣ availability != 'busy'? (se BUSY, callback não muda status)"
puts "     Valor atual: availability='#{account_user.availability}'"
puts "     Resultado: #{check6 ? '✅ PASSOU (não está BUSY)' : '⚠️  ESTÁ EM BUSY (callback não altera)'}"

puts "\n" + "=" * 80
puts "📊 RESUMO:"
puts "=" * 80

if check1 && check2 && check3 && check4 && check5
  if check6
    puts "✅ TODAS as condições passaram!"
    puts "   O callback DEVERIA estar funcionando."
    puts ""
    puts "   Se ainda assim não está funcionando, verifique:"
    puts "   1. Rails foi REALMENTE reiniciado? (Ctrl+C e rodar novamente)"
    puts "   2. Os logs do Terminal 1 mostram a linha '[ActivityPresence] Immediate update'?"
    puts "   3. Há algum erro de exception nos logs?"
  else
    puts "⚠️  O usuário está em BUSY!"
    puts "   O callback NÃO vai mudar o status quando estiver em BUSY."
    puts "   Isso é intencional (respeita a pausa do agente)."
    puts ""
    puts "   Para testar, mude o status para OFFLINE ou ONLINE primeiro."
  end
else
  puts "❌ PROBLEMA ENCONTRADO!"
  puts ""
  puts "   Condições que falharam:"
  puts "   - Condição 1 (sender_type): #{check1 ? '✅' : '❌'}" unless check1
  puts "   - Condição 2 (sender_id): #{check2 ? '✅' : '❌'}" unless check2
  puts "   - Condição 3 (activity_enabled): #{check3 ? '✅' : '❌'}" unless check3
  puts "   - Condição 4 (account_user exists): #{check4 ? '✅' : '❌'}" unless check4
  puts "   - Condição 5 (auto_offline=false): #{check5 ? '✅' : '❌'}" unless check5
end

puts "\n" + "=" * 80
