# Guia Completo: Configurar Ambiente de Desenvolvimento Chatwoot no Windows (WSL2)

Este documento descreve o processo completo para configurar um ambiente de desenvolvimento do Chatwoot em uma máquina Windows usando WSL2 (Ubuntu), conectando a um banco de dados PostgreSQL remoto e Redis local.

## 📋 Índice

- [Pré-requisitos](#pré-requisitos)
- [Parte 1: Configurar WSL2 e Ubuntu](#parte-1-configurar-wsl2-e-ubuntu)
- [Parte 2: Instalar Dependências](#parte-2-instalar-dependências)
- [Parte 3: Configurar o Projeto Chatwoot](#parte-3-configurar-o-projeto-chatwoot)
- [Parte 4: Configurar Banco de Dados e Redis](#parte-4-configurar-banco-de-dados-e-redis)
- [Parte 5: Executar o Ambiente de Desenvolvimento](#parte-5-executar-o-ambiente-de-desenvolvimento)
- [Problemas Comuns e Soluções](#problemas-comuns-e-soluções)
- [Comandos Úteis](#comandos-úteis)

---

## Pré-requisitos

- Windows 10/11 (versão 2004 ou superior)
- Acesso administrador no Windows
- Pelo menos 8GB de RAM
- 20GB de espaço em disco disponível
- Acesso ao banco de dados PostgreSQL de produção (host, porta, credenciais)

---

## Parte 1: Configurar WSL2 e Ubuntu

### 1.1 Instalar WSL2

Abra o PowerShell como Administrador e execute:

```powershell
wsl --install
```

Reinicie o computador quando solicitado.

### 1.2 Instalar Ubuntu

```powershell
wsl --install -d Ubuntu
```

### 1.3 Configurar Ubuntu

Após a instalação, o Ubuntu abrirá automaticamente. Configure:
- Nome de usuário
- Senha

### 1.4 Verificar Distribuições WSL

Para ver todas as distribuições instaladas:

```powershell
wsl -l -v
```

**IMPORTANTE:** Você pode ter múltiplas distribuições (Ubuntu, docker-desktop, etc.). Use sempre a distribuição Ubuntu correta:

```powershell
# Entrar na distribuição correta
wsl -d Ubuntu
```

### 1.5 Navegar até o Projeto

Dentro do Ubuntu WSL, você pode acessar seus arquivos do Windows em `/mnt/`:

```bash
cd /mnt/d/ivox/chatwoot
```

**Estrutura de diretórios:**
- `C:\` → `/mnt/c/`
- `D:\` → `/mnt/d/`
- etc.

---

## Parte 2: Instalar Dependências

### 2.1 Atualizar Sistema

```bash
sudo apt update
sudo apt upgrade -y
```

### 2.2 Instalar Dependências Básicas

```bash
sudo apt install -y curl git build-essential libssl-dev libreadline-dev \
  zlib1g-dev libpq-dev libxml2-dev libxslt1-dev libyaml-dev libffi-dev \
  shared-mime-info imagemagick
```

### 2.3 Instalar Ruby (via rbenv)

```bash
# Instalar rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/main/bin/rbenv-installer | bash

# Adicionar ao PATH
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Verificar instalação
rbenv -v
```

### 2.4 Instalar Ruby 3.4.4

**⚠️ ATENÇÃO:** O projeto Chatwoot usa Ruby 3.4.4. Verifique o arquivo `.ruby-version` no projeto.

```bash
# Instalar Ruby 3.4.4 (DEMORA ~5-10 minutos - é normal!)
rbenv install 3.4.4

# Definir como versão global
rbenv global 3.4.4

# Verificar
ruby -v
# Deve mostrar: ruby 3.4.4

# Instalar Bundler
gem install bundler
```

**💡 Dica:** A compilação do Ruby demora bastante. Seja paciente!

### 2.5 Instalar Node.js (via nvm)

```bash
# Instalar nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Recarregar shell
source ~/.bashrc

# Instalar Node.js 20
nvm install 20
nvm use 20

# Verificar
node -v
npm -v
```

### 2.6 Habilitar Corepack (para pnpm)

**⚠️ IMPORTANTE:** O Chatwoot usa `pnpm`, não `npm` ou `yarn`!

```bash
corepack enable

# Verificar
pnpm -v
```

### 2.7 Instalar Redis (Local)

```bash
sudo apt install -y redis-server

# Iniciar Redis
sudo service redis-server start

# Verificar se está rodando
redis-cli ping
# Deve retornar: PONG
```

---

## Parte 3: Configurar o Projeto Chatwoot

### 3.1 Clonar ou Navegar até o Projeto

Se já tem o projeto:
```bash
cd /mnt/d/ivox/chatwoot
```

Se precisa clonar:
```bash
git clone https://github.com/seu-usuario/chatwoot.git
cd chatwoot
```

### 3.2 Instalar Dependências Ruby

```bash
bundle install
```

Se der erro de versão do Ruby, verifique:
```bash
cat .ruby-version
# Certifique-se de ter instalado exatamente essa versão
```

### 3.3 Instalar Dependências Node

```bash
pnpm install
```

**❌ NÃO use `yarn install` ou `npm install`!**

---

## Parte 4: Configurar Banco de Dados e Redis

### 4.1 Criar Arquivo `.env`

Crie o arquivo `.env` na raiz do projeto:

```bash
# Chatwoot Development Environment

# Database (PRODUCTION - REMOTO)
POSTGRES_HOST=pg.slave.omniflex.com.br
POSTGRES_PORT=25060
POSTGRES_DATABASE=chatwoot_2211
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=sua_senha_aqui

# Redis (LOCAL - para desenvolvimento)
REDIS_URL=redis://localhost:6379

# Rails
RAILS_ENV=development
RAILS_MAX_THREADS=5
SECRET_KEY_BASE=gere_uma_chave_secreta_aqui

# Frontend URL
FRONTEND_URL=http://localhost:3000

# Mail (opcional, para testes locais use mailcatcher)
SMTP_ADDRESS=localhost
SMTP_PORT=1025
SMTP_DOMAIN=chatwoot.local
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=false

# Storage (local development)
ACTIVE_STORAGE_SERVICE=local

# Feature Flags (opcional)
ENABLE_ACCOUNT_SIGNUP=true
```

### 4.2 Gerar SECRET_KEY_BASE

```bash
# Opção 1: usando Rails
bundle exec rails secret

# Opção 2: usando OpenSSL
openssl rand -hex 64
```

Copie a saída e cole no `.env` na linha `SECRET_KEY_BASE=`.

### 4.3 Estratégia de Banco de Dados

**Duas opções:**

#### Opção A: Banco de Dados Remoto (Produção) - RECOMENDADO para testar com dados reais

✅ Vantagens:
- Dados reais para testes
- Não precisa configurar PostgreSQL local

❌ Desvantagens:
- Mais lento (latência de rede)
- Cuidado com mudanças que afetam produção

#### Opção B: Banco de Dados Local

✅ Vantagens:
- Mais rápido
- Seguro para testes

❌ Desvantagens:
- Precisa instalar PostgreSQL
- Não tem dados reais
- Precisa rodar migrations do zero

Para este guia, usamos **Opção A** (banco remoto).

### 4.4 Testar Conexão com Banco

```bash
# Verificar se consegue conectar
bundle exec rails db:version
```

Se conectar com sucesso, verá a versão do schema do banco.

### 4.5 Executar Migrations (se necessário)

```bash
bundle exec rails db:migrate
```

**⚠️ CUIDADO:** Se estiver usando banco de produção, migrations podem afetar produção!

---

## Parte 5: Executar o Ambiente de Desenvolvimento

O Chatwoot precisa de **3 processos rodando simultaneamente**. Abra 3 terminais WSL separados.

### 5.1 Terminal 1: Rails Server

```bash
cd /mnt/d/ivox/chatwoot
bundle exec rails server -p 3000
```

Aguarde até ver:
```
* Listening on http://127.0.0.1:3000
Use Ctrl-C to stop
```

### 5.2 Terminal 2: Sidekiq (Background Jobs)

```bash
cd /mnt/d/ivox/chatwoot
bundle exec sidekiq
```

Aguarde até ver:
```
::: Starting Sidekiq...
```

### 5.3 Terminal 3: Vite (Frontend Dev Server)

```bash
cd /mnt/d/ivox/chatwoot
bin/vite dev
```

**❌ Se der erro de line endings (`\r`):**

```bash
# Corrigir line endings
sed -i 's/\r$//' bin/vite

# Tentar novamente
bin/vite dev
```

Aguarde até ver:
```
VITE vX.X.X ready in XXXms
➜ Local: http://localhost:5173/
```

### 5.4 Acessar a Aplicação

Abra o navegador em:
```
http://localhost:3000
```

**💡 Observação:** O primeiro carregamento pode ser lento devido ao banco remoto.

---

## Problemas Comuns e Soluções

### ❌ Problema 1: `rbenv: version '3.4.4' is not installed`

**Causa:** Versão do Ruby incorreta.

**Solução:**
```bash
rbenv install 3.4.4
rbenv global 3.4.4
ruby -v
```

### ❌ Problema 2: `rake secret` não encontrado

**Causa:** Rails 7+ não tem mais `rake secret`.

**Solução:**
```bash
# Use um destes:
bundle exec rails secret
# OU
openssl rand -hex 64
```

### ❌ Problema 3: `error This project's package.json defines "packageManager": "yarn@pnpm@10.2.0"`

**Causa:** Tentando usar yarn quando o projeto usa pnpm.

**Solução:**
```bash
corepack enable
pnpm install
```

**❌ NUNCA use `yarn install` ou `npm install`!**

### ❌ Problema 4: `/usr/bin/env: 'ruby\r': No such file or directory`

**Causa:** Arquivos com line endings do Windows (`\r\n`) em vez de Unix (`\n`).

**Solução:**
```bash
# Corrigir arquivo específico
sed -i 's/\r$//' bin/vite

# Ou corrigir todos os arquivos bin/
find bin/ -type f -exec sed -i 's/\r$//' {} +
```

### ❌ Problema 5: Aplicação muito lenta

**Causa:** Banco de dados remoto com latência de rede.

**Isso é normal quando usando banco remoto!**

Cada query adiciona ~20-30ms de latência. Para ambiente de desenvolvimento, considere:
- Aceitar a lentidão
- Usar banco local (mais trabalho inicial)
- Usar cache local agressivo

### ❌ Problema 6: Tradução não aparece / i18n em inglês

**Causa:** Cache do Vite não recarregou arquivos JSON de tradução.

**Solução:**
```bash
# Parar Vite (Ctrl+C no Terminal 3)

# Limpar cache
rm -rf node_modules/.vite tmp/cache public/packs

# Rodar Vite novamente
bin/vite dev

# No navegador: Ctrl+Shift+R (hard refresh)
```

### ❌ Problema 7: Redis não conecta

**Causa:** Redis não está rodando.

**Solução:**
```bash
# Iniciar Redis
sudo service redis-server start

# Verificar
redis-cli ping
# Deve retornar: PONG
```

### ❌ Problema 8: Entrei no WSL errado

**Problema:** Digitou `wsl` e entrou no docker-desktop em vez do Ubuntu.

**Como identificar:**
```bash
pwd
# Se mostrar algo como /root e não encontrar /mnt/d, está no lugar errado
```

**Solução:**
```bash
# Sair do WSL atual
exit

# Entrar no correto
wsl -d Ubuntu
```

### ❌ Problema 9: Fechei o PowerShell e perdi a sessão

**Solução:**
```bash
# Abrir novo PowerShell
wsl -d Ubuntu

# Navegar até o projeto
cd /mnt/d/ivox/chatwoot

# Verificar processos rodando
ps aux | grep rails
ps aux | grep sidekiq
```

Se os processos não estão rodando, reabrir os 3 terminais conforme [Parte 5](#parte-5-executar-o-ambiente-de-desenvolvimento).

---

## Comandos Úteis

### Gerenciamento WSL

```powershell
# Listar distribuições
wsl -l -v

# Entrar em distribuição específica
wsl -d Ubuntu

# Encerrar distribuição
wsl --terminate Ubuntu

# Reiniciar WSL
wsl --shutdown
```

### Gerenciamento de Serviços (dentro do Ubuntu)

```bash
# Redis
sudo service redis-server start
sudo service redis-server stop
sudo service redis-server status

# Verificar portas em uso
netstat -tulpn | grep LISTEN
```

### Git

```bash
# Ver status
git status

# Ver branch atual
git branch

# Ver últimos commits
git log --oneline -5

# Mudar de branch
git checkout nome-da-branch
```

### Rails

```bash
# Console Rails
bundle exec rails console

# Ver rotas
bundle exec rails routes | grep api

# Ver versão do schema
bundle exec rails db:version

# Rollback última migration
bundle exec rails db:rollback

# Ver logs
tail -f log/development.log
```

### Limpar Cache

```bash
# Limpar tudo
rm -rf tmp/cache public/packs node_modules/.vite

# Apenas cache Rails
rm -rf tmp/cache

# Apenas cache Vite
rm -rf node_modules/.vite
```

### Debugging

```bash
# Ver processos Rails/Sidekiq/Vite rodando
ps aux | grep -E "(rails|sidekiq|vite)" | grep -v grep

# Ver uso de memória
free -h

# Ver espaço em disco
df -h

# Testar conexão com banco
bundle exec rails runner "puts ActiveRecord::Base.connection.execute('SELECT version()').first"

# Testar Redis
redis-cli ping
```

---

## Workflow Diário

### Iniciar Ambiente

1. Abrir PowerShell
2. Entrar no Ubuntu WSL:
   ```powershell
   wsl -d Ubuntu
   ```
3. Navegar até o projeto:
   ```bash
   cd /mnt/d/ivox/chatwoot
   ```
4. Iniciar Redis:
   ```bash
   sudo service redis-server start
   ```
5. Abrir 3 terminais e rodar:
   - Terminal 1: `bundle exec rails server -p 3000`
   - Terminal 2: `bundle exec sidekiq`
   - Terminal 3: `bin/vite dev`

### Finalizar Ambiente

1. Em cada terminal: `Ctrl+C`
2. Opcionalmente, parar Redis:
   ```bash
   sudo service redis-server stop
   ```

---

## Checklist de Troubleshooting

Antes de pedir ajuda, verifique:

- [ ] Estou no WSL correto? (`wsl -l -v` → Ubuntu)
- [ ] Estou no diretório correto? (`pwd` → `/mnt/d/ivox/chatwoot`)
- [ ] Ruby versão correta? (`ruby -v` → 3.4.4)
- [ ] Node versão correta? (`node -v` → v20.x.x)
- [ ] Redis rodando? (`redis-cli ping` → PONG)
- [ ] `.env` configurado? (`cat .env | grep SECRET_KEY_BASE`)
- [ ] Dependências instaladas? (`bundle check` e `pnpm list`)
- [ ] 3 processos rodando? (Rails, Sidekiq, Vite)
- [ ] Banco de dados acessível? (`bundle exec rails db:version`)

---

## Arquitetura do Setup

```
┌─────────────────────────────────────────────────────────┐
│ Windows 10/11                                           │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │ WSL2 - Ubuntu                                     │  │
│  │                                                   │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌─────────┐ │  │
│  │  │ Rails :3000 │  │ Sidekiq      │  │ Vite    │ │  │
│  │  │ (Backend)   │  │ (Jobs)       │  │ :5173   │ │  │
│  │  └──────┬──────┘  └──────┬───────┘  └────┬────┘ │  │
│  │         │                │                │      │  │
│  │         └────────┬───────┴────────────────┘      │  │
│  │                  │                               │  │
│  │         ┌────────▼────────┐                      │  │
│  │         │ Redis (Local)   │                      │  │
│  │         │ :6379           │                      │  │
│  │         └─────────────────┘                      │  │
│  │                                                   │  │
│  └───────────────────────────┬───────────────────────┘  │
│                              │                          │
└──────────────────────────────┼──────────────────────────┘
                               │
                               │ (Internet)
                               │
                    ┌──────────▼──────────┐
                    │ PostgreSQL (Remoto) │
                    │ :25060              │
                    └─────────────────────┘
```

---

## Próximos Passos

Depois de ter o ambiente funcionando:

1. Familiarize-se com a estrutura do projeto
2. Leia a documentação oficial do Chatwoot
3. Configure seu editor de código (VS Code recomendado)
4. Instale extensões úteis:
   - Ruby
   - Vue Language Features (Volar)
   - ESLint
   - Prettier

---

## Recursos Adicionais

- [Documentação Oficial Chatwoot](https://www.chatwoot.com/docs/)
- [WSL2 Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [rbenv GitHub](https://github.com/rbenv/rbenv)
- [nvm GitHub](https://github.com/nvm-sh/nvm)

---

**Criado em:** 2025-01-22
**Última atualização:** 2025-01-22
**Versão Chatwoot:** 4.7.0
**Versão Ruby:** 3.4.4
**Versão Node:** 20.x
