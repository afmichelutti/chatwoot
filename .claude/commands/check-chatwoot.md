---
description: Verificar status do ambiente de desenvolvimento Chatwoot
---

# Check Chatwoot Development Environment

Verificando o status do ambiente de desenvolvimento Chatwoot...

## 🔍 Executar Diagnóstico Completo

Por favor, execute os seguintes comandos no seu terminal WSL para diagnosticar o estado atual:

---

## 1️⃣ Verificar WSL e Diretório

```bash
# Ver qual WSL está usando
wsl -l -v

# Ver diretório atual
pwd

# Deve estar em: /mnt/d/ivox/chatwoot
```

**✅ Correto:** Está na distribuição Ubuntu e no diretório do projeto

---

## 2️⃣ Verificar Versões

```bash
# Ruby
ruby -v
# Esperado: ruby 3.4.4

# Node
node -v
# Esperado: v20.x.x

# pnpm
pnpm -v
# Esperado: 9.x.x ou 10.x.x

# Bundler
bundle -v
# Esperado: 2.x.x
```

**✅ Correto:** Todas as versões correspondem

---

## 3️⃣ Verificar Serviços

### Redis
```bash
# Iniciar Redis (se não estiver rodando)
sudo service redis-server start

# Testar conexão
redis-cli ping
# Esperado: PONG

# Ver informações do Redis
redis-cli info server | head -10
```

**✅ Correto:** Redis responde com PONG

### PostgreSQL (Remoto)
```bash
# Testar conexão com banco de dados
bundle exec rails runner "puts ActiveRecord::Base.connection.execute('SELECT version()').first"

# Ver versão do schema
bundle exec rails db:version
```

**✅ Correto:** Conexão estabelecida e retorna versão

---

## 4️⃣ Verificar Processos Rodando

```bash
# Ver todos os processos relacionados ao Chatwoot
ps aux | grep -E "(rails|sidekiq|vite)" | grep -v grep
```

**Análise dos resultados:**

- **Se vazio:** Nenhum processo rodando (ambiente parado)
- **Se aparecer `rails server`:** Rails rodando ✅
- **Se aparecer `sidekiq`:** Sidekiq rodando ✅
- **Se aparecer `vite`:** Vite rodando ✅

---

## 5️⃣ Verificar Portas

```bash
# Porta 3000 (Rails)
lsof -i :3000

# Porta 5173 (Vite)
lsof -i :5173

# Porta 6379 (Redis)
lsof -i :6379
```

**Análise:**
- **Porta 3000 em uso:** Rails rodando ✅
- **Porta 5173 em uso:** Vite rodando ✅
- **Porta 6379 em uso:** Redis rodando ✅

---

## 6️⃣ Verificar Logs

### Ver últimas linhas do log de desenvolvimento
```bash
tail -30 log/development.log
```

### Ver se há erros recentes
```bash
grep -i "error\|exception\|fatal" log/development.log | tail -20
```

### Ver log do Sidekiq
```bash
tail -30 log/sidekiq.log
```

---

## 7️⃣ Verificar Dependências

### Ruby (Gems)
```bash
bundle check
```

**✅ Correto:** "The Gemfile's dependencies are satisfied"

**❌ Problema:** "The following gems are missing"
```bash
# Solução:
bundle install
```

### Node (Pacotes)
```bash
pnpm list --depth=0 2>&1 | head -20
```

**✅ Correto:** Lista de pacotes sem erros

---

## 8️⃣ Verificar Arquivo .env

```bash
# Ver se .env existe
ls -la .env

# Ver variáveis críticas (sem expor senhas)
cat .env | grep -E "POSTGRES_HOST|REDIS_URL|RAILS_ENV|SECRET_KEY_BASE" | sed 's/=.*/=***/'
```

**✅ Correto:** Arquivo existe e contém variáveis necessárias

---

## 9️⃣ Verificar Git Status

```bash
# Ver branch atual
git branch --show-current

# Ver status
git status --short

# Ver últimos commits
git log --oneline -5
```

**Informações úteis:**
- Branch atual
- Arquivos modificados
- Commits recentes

---

## 🔟 Verificar Recursos do Sistema

```bash
# Memória
free -h

# Espaço em disco
df -h | grep -E "Filesystem|/mnt/d"

# CPU (top 5 processos)
ps aux --sort=-%cpu | head -6
```

**⚠️ Atenção se:**
- Memória disponível < 1GB
- Disco < 5GB livre
- CPU de algum processo > 80%

---

## 🏥 Status Geral

Com base nos comandos acima, você pode determinar:

### ✅ Ambiente Saudável (tudo funcionando)
- [x] WSL Ubuntu correto
- [x] Diretório correto
- [x] Versões corretas (Ruby 3.4.4, Node 20.x)
- [x] Redis respondendo (PONG)
- [x] Banco de dados acessível
- [x] 3 processos rodando (Rails, Sidekiq, Vite)
- [x] Portas 3000, 5173, 6379 em uso
- [x] Dependências instaladas
- [x] .env configurado
- [x] Sem erros recentes nos logs

**🎉 Status:** Pronto para desenvolver!

---

### ⚠️ Ambiente Parcial (alguns problemas)
- [ ] Alguns processos não rodando
- [ ] Redis parado
- [ ] Dependências desatualizadas
- [ ] Warnings nos logs

**🔧 Status:** Precisa de ajustes. Consulte `/start-chatwoot` ou documentação.

---

### ❌ Ambiente com Problemas (não funciona)
- [ ] Versões erradas
- [ ] Banco de dados não conecta
- [ ] Erros críticos nos logs
- [ ] Dependências faltando

**🚨 Status:** Precisa de troubleshooting. Consulte [docs/SETUP_WINDOWS_WSL.md](../docs/SETUP_WINDOWS_WSL.md)

---

## 🛠️ Ações Rápidas

### Se ambiente está parado mas está OK:
```bash
/start-chatwoot
```

### Se há dependências faltando:
```bash
bundle install
pnpm install
```

### Se há erros de cache:
```bash
rm -rf tmp/cache node_modules/.vite public/packs
```

### Se Redis não está rodando:
```bash
sudo service redis-server start
redis-cli ping
```

### Se precisa reiniciar tudo:
```bash
/stop-chatwoot
# Aguardar tudo parar
/start-chatwoot
```

---

## 📊 Comandos de Diagnóstico Avançado

### Testar ActiveRecord (Rails Console)
```bash
bundle exec rails console
```

Dentro do console:
```ruby
# Testar conexão com banco
ActiveRecord::Base.connection.active?

# Contar registros
Account.count
User.count
Message.count

# Ver última mensagem
Message.last

# Sair
exit
```

### Testar Redis (Redis CLI)
```bash
redis-cli
```

Dentro do CLI:
```redis
# Testar conexão
PING

# Ver keys de presença
KEYS ONLINE_*

# Ver status de um usuário
GET ONLINE_STATUS:1:User:1

# Ver info
INFO

# Sair
EXIT
```

### Testar Sidekiq
```bash
bundle exec rails console
```

```ruby
# Ver filas
Sidekiq::Queue.all.each {|q| puts "#{q.name}: #{q.size} jobs"}

# Ver jobs agendados
Sidekiq::ScheduledSet.new.size

# Ver workers ativos
Sidekiq::Workers.new.size

# Sair
exit
```

---

## 📚 Documentação de Referência

- **Setup completo:** [docs/SETUP_WINDOWS_WSL.md](../docs/SETUP_WINDOWS_WSL.md)
- **Troubleshooting:** Seção "Problemas Comuns" no setup
- **Iniciar ambiente:** `/start-chatwoot`
- **Parar ambiente:** `/stop-chatwoot`

---

**Execute os comandos acima e me informe os resultados para diagnóstico mais preciso!**
