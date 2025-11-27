---
description: Guia para iniciar o ambiente de desenvolvimento Chatwoot no Windows (WSL)
---

# Start Chatwoot Development Environment

Você está iniciando o ambiente de desenvolvimento do Chatwoot no Windows usando WSL2.

## 🎯 Objetivo

Iniciar os 3 processos necessários para rodar o Chatwoot localmente:
1. **Rails Server** (Backend - porta 3000)
2. **Sidekiq** (Background Jobs)
3. **Vite** (Frontend Dev Server - porta 5173)

---

## 📋 Checklist Pré-Inicialização

Antes de começar, execute os seguintes comandos de verificação:

### 1. Verificar se está no WSL correto
```bash
wsl -d Ubuntu
cd /mnt/d/ivox/chatwoot
pwd
```
**Esperado:** `/mnt/d/ivox/chatwoot`

### 2. Verificar versões
```bash
ruby -v    # Esperado: 3.4.4
node -v    # Esperado: v20.x.x
pnpm -v    # Deve retornar uma versão
```

### 3. Verificar Redis
```bash
sudo service redis-server start
redis-cli ping
```
**Esperado:** `PONG`

### 4. Verificar conexão com banco de dados
```bash
bundle exec rails db:version
```
**Esperado:** Retorna a versão do schema (ex: `20250118000001`)

---

## 🚀 Iniciando o Ambiente

Você precisa abrir **3 terminais WSL** separados. Siga os passos abaixo:

### Terminal 1: Rails Server

```bash
# Entrar no WSL
wsl -d Ubuntu

# Navegar até o projeto
cd /mnt/d/ivox/chatwoot

# Iniciar Rails
bundle exec rails server -p 3000
```

**✅ Sucesso quando ver:**
```
* Listening on http://127.0.0.1:3000
Use Ctrl-C to stop
```

**⏱️ Tempo:** ~10-20 segundos

---

### Terminal 2: Sidekiq (Background Jobs)

```bash
# Entrar no WSL
wsl -d Ubuntu

# Navegar até o projeto
cd /mnt/d/ivox/chatwoot

# Iniciar Sidekiq
bundle exec sidekiq
```

**✅ Sucesso quando ver:**
```
::: Starting Sidekiq...
```

**⏱️ Tempo:** ~5-10 segundos

---

### Terminal 3: Vite (Frontend)

```bash
# Entrar no WSL
wsl -d Ubuntu

# Navegar até o projeto
cd /mnt/d/ivox/chatwoot

# Iniciar Vite
bin/vite dev
```

**✅ Sucesso quando ver:**
```
VITE vX.X.X ready in XXXms
➜ Local: http://localhost:5173/
```

**⏱️ Tempo:** ~5-15 segundos

---

## 🌐 Acessar a Aplicação

Depois que os 3 processos estiverem rodando:

**URL:** http://localhost:3000

**💡 Observação:** O primeiro carregamento pode ser lento devido ao banco de dados remoto (latência de rede ~20-30ms por query).

---

## ❌ Problemas Comuns

### Problema 1: Redis não está rodando

**Erro:**
```
Error connecting to Redis on localhost:6379
```

**Solução:**
```bash
sudo service redis-server start
redis-cli ping  # Deve retornar PONG
```

---

### Problema 2: Erro de line endings no Vite

**Erro:**
```
/usr/bin/env: 'ruby\r': No such file or directory
```

**Solução:**
```bash
sed -i 's/\r$//' bin/vite
bin/vite dev
```

---

### Problema 3: Porta 3000 já está em uso

**Erro:**
```
Address already in use - bind(2) for 127.0.0.1:3000
```

**Solução:**
```bash
# Ver processo usando a porta
lsof -i :3000

# Matar processo
kill -9 <PID>

# Ou usar outra porta
bundle exec rails server -p 3001
```

---

### Problema 4: Ruby version incorreta

**Erro:**
```
rbenv: version '3.4.4' is not installed
```

**Solução:**
```bash
rbenv install 3.4.4
rbenv global 3.4.4
ruby -v
```

---

### Problema 5: Dependências desatualizadas

**Erro:**
```
Could not find gem 'XXX'
```

**Solução:**
```bash
# Ruby
bundle install

# Node
pnpm install
```

---

### Problema 6: Cache corrompido

**Sintomas:** Erros estranhos, comportamento inconsistente

**Solução:**
```bash
# Limpar cache
rm -rf tmp/cache public/packs node_modules/.vite

# Reiniciar Vite (Terminal 3)
bin/vite dev

# Hard refresh no navegador
# Ctrl+Shift+R
```

---

## 🛑 Como Parar o Ambiente

Para parar todos os processos:

1. **Terminal 1 (Rails):** `Ctrl+C`
2. **Terminal 2 (Sidekiq):** `Ctrl+C`
3. **Terminal 3 (Vite):** `Ctrl+C`

**Opcional:** Parar Redis
```bash
sudo service redis-server stop
```

---

## 📊 Monitoramento

### Ver logs em tempo real

**Rails:**
```bash
tail -f log/development.log
```

**Sidekiq (em outro terminal):**
```bash
tail -f log/sidekiq.log
```

### Verificar processos rodando
```bash
ps aux | grep -E "(rails|sidekiq|vite)" | grep -v grep
```

### Verificar uso de memória
```bash
free -h
```

---

## 🔍 Troubleshooting Avançado

### Testar conexão com banco de dados
```bash
bundle exec rails runner "puts ActiveRecord::Base.connection.execute('SELECT version()').first"
```

### Testar Redis
```bash
redis-cli
> PING
PONG
> GET ONLINE_STATUS:1:User:1
> EXIT
```

### Rails Console (debugging)
```bash
bundle exec rails console

# Dentro do console:
> Account.count
> User.count
> Message.last
```

---

## 📚 Documentação Completa

Para mais detalhes, consulte:

- **Setup completo:** [docs/SETUP_WINDOWS_WSL.md](../docs/SETUP_WINDOWS_WSL.md)
- **Activity-Based Presence:** [docs/ACTIVITY_BASED_PRESENCE.md](../docs/ACTIVITY_BASED_PRESENCE.md)

---

## 🎬 Workflow Diário

### Manhã (Iniciar)
1. Abrir PowerShell
2. `wsl -d Ubuntu`
3. `cd /mnt/d/ivox/chatwoot`
4. `sudo service redis-server start`
5. Abrir 3 terminais e rodar Rails, Sidekiq, Vite

### Noite (Finalizar)
1. `Ctrl+C` em cada terminal
2. Opcional: `sudo service redis-server stop`

---

## ✅ Checklist de Sucesso

Quando tudo estiver funcionando, você deve ver:

- [ ] Terminal 1: `Listening on http://127.0.0.1:3000`
- [ ] Terminal 2: `Starting Sidekiq...`
- [ ] Terminal 3: `VITE vX.X.X ready`
- [ ] Redis: `redis-cli ping` → `PONG`
- [ ] Navegador: http://localhost:3000 carrega a aplicação
- [ ] Consegue fazer login
- [ ] Vê dados do banco de produção

---

**Se tudo funcionou, você está pronto para desenvolver! 🎉**

**Se algo deu errado, revise a seção de Problemas Comuns acima ou consulte a documentação completa.**
