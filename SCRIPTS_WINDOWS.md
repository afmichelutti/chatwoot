# Scripts Windows para Desenvolvimento Chatwoot

Scripts `.bat` para facilitar o gerenciamento do ambiente de desenvolvimento do Chatwoot no Windows com WSL2.

## 📁 Scripts Disponíveis

### 🚀 [start-chatwoot.bat](start-chatwoot.bat)
**Inicia o ambiente de desenvolvimento automaticamente**

**O que faz:**
1. ✅ Verifica se WSL e Ubuntu estão instalados
2. ✅ Verifica se o diretório do projeto existe
3. ✅ Inicia o Redis
4. ✅ Abre 3 terminais WSL automaticamente:
   - Terminal 1: Rails Server (porta 3000)
   - Terminal 2: Sidekiq (background jobs)
   - Terminal 3: Vite (frontend dev server)
5. ✅ Oferece abrir o navegador automaticamente

**Como usar:**
```cmd
# Duplo clique no arquivo ou
start-chatwoot.bat
```

**Tempo:** ~30-60 segundos até tudo iniciar

---

### 🛑 [stop-chatwoot.bat](stop-chatwoot.bat)
**Para o ambiente de desenvolvimento**

**O que faz:**
1. ✅ Para Rails Server gracefully
2. ✅ Para Sidekiq (aguarda jobs finalizarem)
3. ✅ Para Vite
4. ✅ Oferece parar Redis (opcional)
5. ✅ Verifica se tudo foi parado
6. ✅ Oferece força parada se necessário

**Como usar:**
```cmd
stop-chatwoot.bat
```

---

### 🔍 [check-chatwoot.bat](check-chatwoot.bat)
**Verifica o status do ambiente**

**O que faz:**
1. ✅ Verifica WSL e Ubuntu
2. ✅ Verifica diretório do projeto
3. ✅ Mostra versões (Ruby, Node, pnpm)
4. ✅ Testa Redis (PING)
5. ✅ Testa conexão com banco de dados
6. ✅ Lista processos rodando (Rails, Sidekiq, Vite)
7. ✅ Verifica portas em uso (3000, 5173, 6379)
8. ✅ Mostra status geral do ambiente

**Como usar:**
```cmd
check-chatwoot.bat
```

---

## 🔄 Workflow Diário

### 📅 Início do Dia
```cmd
# 1. Verificar estado atual
check-chatwoot.bat

# 2. Iniciar ambiente
start-chatwoot.bat

# 3. Aguardar ~30-60 segundos
# 4. Acessar http://localhost:3000
```

### 🏁 Fim do Dia
```cmd
# 1. Parar ambiente
stop-chatwoot.bat

# 2. Escolher se quer parar Redis também
```

---

## 🎯 Vantagens dos Scripts

### ✅ Automação
- Não precisa abrir 3 terminais manualmente
- Não precisa lembrar comandos
- Não precisa navegar até o diretório em cada terminal

### ✅ Verificação
- Scripts verificam pré-requisitos antes de executar
- Mostram mensagens claras de erro
- Indicam o que está faltando

### ✅ Consistência
- Sempre executa os comandos corretos
- Sempre na ordem certa
- Sempre no diretório certo

### ✅ Segurança
- Para processos gracefully
- Aguarda jobs do Sidekiq finalizarem
- Verifica antes de forçar parada

---

## ⚙️ Requisitos

Para os scripts funcionarem:

- [x] Windows 10/11
- [x] WSL2 instalado
- [x] Ubuntu distribuição instalada no WSL
- [x] Projeto Chatwoot em `D:\ivox\chatwoot`
- [x] Ambiente configurado conforme [docs/SETUP_WINDOWS_WSL.md](docs/SETUP_WINDOWS_WSL.md)

---

## 🔧 Personalização

### Mudar Caminho do Projeto

Se seu projeto está em outro local, edite os scripts:

```batch
REM De:
cd /mnt/d/ivox/chatwoot

REM Para (exemplo):
cd /mnt/c/projetos/chatwoot
```

### Mudar Distribuição WSL

Se usa outra distribuição:

```batch
REM De:
wsl -d Ubuntu

REM Para (exemplo):
wsl -d Ubuntu-22.04
```

### Mudar Portas

Se Rails roda em outra porta:

```batch
REM De:
bundle exec rails server -p 3000

REM Para:
bundle exec rails server -p 3001
```

---

## ❌ Troubleshooting

### Problema: "WSL não encontrado"

**Solução:**
```powershell
# Instalar WSL
wsl --install
```

### Problema: "Ubuntu não encontrado"

**Solução:**
```powershell
# Instalar Ubuntu
wsl --install -d Ubuntu
```

### Problema: "Diretório do projeto não encontrado"

**Verificar:**
```powershell
wsl -d Ubuntu
cd /mnt/d/ivox/chatwoot
pwd
```

Se não existir, ajuste o caminho nos scripts.

### Problema: "Redis não responde"

**Solução:**
```bash
wsl -d Ubuntu
sudo service redis-server start
redis-cli ping
```

### Problema: "Processos não param"

**Solução:**
Use a opção de forçar parada no `stop-chatwoot.bat` ou:

```bash
wsl -d Ubuntu
pkill -9 -f "rails server"
pkill -9 -f "sidekiq"
pkill -9 -f "vite"
```

### Problema: "Permissões do sudo no Redis"

**Solução:**
Configure sudo sem senha para o serviço Redis:

```bash
# Editar sudoers
sudo visudo

# Adicionar no final:
%sudo ALL=(ALL) NOPASSWD: /usr/sbin/service redis-server *
```

---

## 📊 Comparação: Script vs Manual

| Tarefa | Manual | Com Script |
|--------|--------|------------|
| Abrir terminais | 3x abrir + navegar | 1x duplo clique |
| Tempo | ~2-3 minutos | ~30 segundos |
| Erros de digitação | Possível | Não |
| Esquecer comando | Possível | Não |
| Verificações | Manual | Automático |

---

## 🔗 Comandos Relacionados

Além dos scripts `.bat`, também existem **slash commands** para uso interativo:

- `/start-chatwoot` - Guia manual detalhado
- `/stop-chatwoot` - Instruções de parada
- `/check-chatwoot` - Lista de comandos de diagnóstico
- `/debug-automation` - Debug de automações

**Documentação:** [.claude/commands/README.md](.claude/commands/README.md)

---

## 📚 Documentação Completa

Para informações detalhadas sobre o setup e troubleshooting:

- **Setup Windows/WSL:** [docs/SETUP_WINDOWS_WSL.md](docs/SETUP_WINDOWS_WSL.md)
- **Activity-Based Presence:** [docs/ACTIVITY_BASED_PRESENCE.md](docs/ACTIVITY_BASED_PRESENCE.md)
- **Slash Commands:** [.claude/commands/README.md](.claude/commands/README.md)

---

## 🎬 Demo

### Iniciar Ambiente

```cmd
D:\ivox\chatwoot> start-chatwoot.bat

========================================
  Chatwoot Development Environment
========================================

Iniciando ambiente de desenvolvimento...

[OK] WSL encontrado
[OK] Ubuntu encontrado
[OK] Diretorio do projeto encontrado

Iniciando Redis...
[OK] Redis iniciado com sucesso

========================================
Abrindo terminais...
========================================

Terminal 1: Rails Server (porta 3000)
Terminal 2: Sidekiq (background jobs)
Terminal 3: Vite (frontend dev server)

Aguarde os 3 terminais abrirem...

========================================
  Ambiente Iniciado!
========================================

3 terminais foram abertos:
  1. Rails Server (http://localhost:3000)
  2. Sidekiq
  3. Vite (http://localhost:5173)

Aguarde ~30-60 segundos para tudo inicializar.

Quando estiver pronto, acesse:
  http://localhost:3000

Abrir navegador agora? (S/N): S
Abrindo navegador...
```

### Verificar Status

```cmd
D:\ivox\chatwoot> check-chatwoot.bat

========================================
  Chatwoot Environment Status
========================================

[1/9] Verificando WSL...
[OK] WSL instalado

[2/9] Verificando Ubuntu...
[OK] Ubuntu encontrado

[3/9] Verificando diretorio do projeto...
[OK] Diretorio do projeto existe

[4/9] Verificando versoes...

Ruby:
ruby 3.4.4

Node:
v20.19.0

pnpm:
10.2.0

[5/9] Verificando Redis...
[OK] Redis esta rodando (responde PONG)

[6/9] Verificando conexao com banco de dados...
Current version: 20250118000001

[7/9] Verificando processos rodando...

[OK] Rails Server: RODANDO
[OK] Sidekiq: RODANDO
[OK] Vite: RODANDO

[8/9] Verificando portas em uso...

[OK] Porta 3000 (Rails): EM USO
[OK] Porta 5173 (Vite): EM USO
[OK] Porta 6379 (Redis): EM USO

[9/9] Status Geral...

========================================

[OK] AMBIENTE COMPLETO RODANDO!

Tudo esta funcionando:
  - Rails Server: http://localhost:3000
  - Vite: http://localhost:5173
  - Sidekiq: Rodando
  - Redis: Rodando

Voce esta pronto para desenvolver!

========================================
```

---

## ✨ Contribuindo

Se encontrar bugs ou tiver sugestões de melhorias nos scripts:

1. Teste a mudança localmente
2. Documente a mudança
3. Atualize este README se necessário

---

**Criado em:** 2025-01-22
**Última atualização:** 2025-01-22
**Versão:** 1.0
