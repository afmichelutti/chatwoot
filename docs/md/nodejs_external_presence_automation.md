# Node.js External Presence Automation

## Objetivo

Criar uma automação **externa** (Node.js + Prisma) que gerencia a presença de agentes da **account_id = 1** baseado em **atividade real** (envio de mensagens), independente do WebSocket/heartbeat do Chatwoot.

---

## Requisitos

### Comportamento Desejado

1. **Ignorar heartbeat do Redis** (WebSocket) para determinar online/offline
2. **Baseado em atividade**:
   - Agente **escreve mensagem** → Marca como **online**
   - Agente **sem escrever mensagem há 10+ minutos** → Marca como **offline**
3. **Respeitar status "busy" (pausa)**:
   - Agente em **"busy"** (pausa/almoço) → **NÃO muda** para offline automaticamente
   - Agente em **"busy" há 3+ horas** → Marca como **offline** (esqueceu de voltar)
4. **Job 24/7** rodando a cada 20 segundos

---

## Arquitetura da Solução

### Decisão: Usar `auto_offline = false`

#### ✅ Resposta: SIM, use `auto_offline = false` para account_id = 1

Quando `auto_offline = false`:

```ruby
# app/models/concerns/availability_statusable.rb:23-29
def user_availability_status
  return availability unless auto_offline  # ← auto_offline=false → Retorna DB direto

  # Código abaixo é IGNORADO quando auto_offline=false
  online_presence? ? (redis_status || availability) : 'offline'
end
```

**Isso significa**:
- ✅ Chatwoot **ignora** heartbeat do WebSocket
- ✅ Chatwoot **ignora** `ONLINE_PRESENCE` do Redis (timestamp)
- ✅ Chatwoot usa **APENAS** o campo `availability` da tabela `account_users`
- ✅ Sua automação Node.js controla 100% o status

---

### ⚠️ Resposta: PARCIALMENTE - Precisa Atenção no Redis!

#### Por quê?

1. **WebSocket ainda funciona** (envia heartbeat):
   - Frontend continua enviando heartbeat a cada 20s
   - Redis `ONLINE_PRESENCE::1::USERS` é atualizado normalmente
   - **Chatwoot ignora** `ONLINE_PRESENCE` quando `auto_offline=false` ✅

2. **⚠️ IMPORTANTE: WebSocket Broadcast LÊ Redis `ONLINE_STATUS`**:
   - `room_channel.rb` usa `OnlineStatusTracker.get_available_users()`
   - Esse método **LÊ Redis** `ONLINE_STATUS::1` (mesmo com `auto_offline=false`)
   - Se Redis estiver desatualizado, WebSocket broadcast envia status errado!

3. **Solução: Sincronizar Redis Manualmente**:
   - Quando sua automação Node.js atualiza `availability` no DB
   - **DEVE** também atualizar Redis `ONLINE_STATUS::1`
   - Porque callback Rails `after_save` **NÃO dispara** via Prisma (DB externo)

#### Inconsistência Arquitetural do Chatwoot

| Contexto | auto_offline=false funciona? | Fonte de Dados |
|----------|------------------------------|----------------|
| **API `/api/v1/profile`** | ✅ Sim | DB (ignora Redis) |
| **Jbuilder views** | ✅ Sim | DB (ignora Redis) |
| **WebSocket `presence.update`** | ❌ **NÃO!** | **Redis** `ONLINE_STATUS::1` |

**Conclusão**: Você TEM controle, MAS precisa atualizar **DB + Redis** manualmente.

---

## Configuração Inicial

### 1. Desabilitar auto_offline para account_id = 1

```ruby
# Rails Console (Chatwoot)
AccountUser.where(account_id: 1).find_each do |au|
  au.update!(auto_offline: false)
end

# Verificar
AccountUser.where(account_id: 1).pluck(:auto_offline).uniq
# Deve retornar: [false]
```

---

### 2. Schema Prisma (Node.js)

```prisma
// schema.prisma

model User {
  id            Int             @id @default(autoincrement())
  name          String?
  email         String
  // ... outros campos

  accountUsers  AccountUser[]
  messages      Message[]

  @@map("users")
}

model AccountUser {
  id            Int       @id @default(autoincrement())
  accountId     Int       @map("account_id")
  userId        Int       @map("user_id")
  availability  String    @default("offline")  // 'online', 'offline', 'busy'
  autoOffline   Boolean   @default(true) @map("auto_offline")
  createdAt     DateTime  @default(now()) @map("created_at")
  updatedAt     DateTime  @updatedAt @map("updated_at")

  user          User      @relation(fields: [userId], references: [id])

  @@map("account_users")
  @@index([accountId])
  @@index([userId])
}

model Message {
  id                Int       @id @default(autoincrement())
  content           String?
  accountId         Int       @map("account_id")
  inboxId           Int       @map("inbox_id")
  conversationId    Int       @map("conversation_id")
  messageType       Int       @default(0) @map("message_type")  // 0=incoming, 1=outgoing, 2=activity
  createdAt         DateTime  @default(now()) @map("created_at")
  updatedAt         DateTime  @updatedAt @map("updated_at")
  senderId          Int?      @map("sender_id")
  senderType        String?   @map("sender_type")  // 'User', 'Contact'

  sender            User?     @relation(fields: [senderId], references: [id])

  @@map("messages")
  @@index([accountId])
  @@index([conversationId])
  @@index([senderId, senderType])
  @@index([createdAt])
}

model Conversation {
  id              Int       @id @default(autoincrement())
  accountId       Int       @map("account_id")
  inboxId         Int       @map("inbox_id")
  status          Int       @default(0)  // 0=open, 1=resolved, 2=pending
  assigneeId      Int?      @map("assignee_id")
  createdAt       DateTime  @default(now()) @map("created_at")
  updatedAt       DateTime  @updatedAt @map("updated_at")

  @@map("conversations")
  @@index([accountId])
  @@index([assigneeId])
}
```

---

## ⭐ MELHOR SOLUÇÃO: Usar API do Chatwoot

### Por que usar a API?

✅ **Vantagens**:
1. **Callbacks Rails disparam automaticamente** → Redis sincronizado ✅
2. **WebSocket broadcast funciona** → UI atualiza instantaneamente ✅
3. **Não precisa acessar Redis diretamente** → Mais simples ✅
4. **Auditoria completa** → Rails logs registram todas mudanças ✅
5. **Validações do modelo aplicadas** → Seguro ✅

❌ **Desvantagens**:
1. Pequena latência extra (HTTP request)
2. Precisa ter API token válido

---

### Endpoint Disponível

```
POST /api/v1/profile/availability
```

**Request**:
```bash
curl -X POST https://seu-chatwoot.com/api/v1/profile/availability \
  -H "api_access_token: SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "profile": {
      "account_id": 1,
      "availability": "online"
    }
  }'
```

**Response**: `200 OK`

---

### Como Obter API Token

Cada usuário tem um `api_access_token` único:

```sql
-- PostgreSQL
SELECT id, email, name, api_access_token
FROM users
WHERE id IN (
  SELECT user_id
  FROM account_users
  WHERE account_id = 1
);
```

**OU** criar um usuário dedicado para automação:

1. Criar user "automation@suaempresa.com"
2. Adicionar à account_id=1
3. Usar `api_access_token` desse user
4. Chamar API em nome de cada agente passando `user_id`

---

## Implementação Node.js (Usando API)

### Estrutura de Arquivos

```
presence-automation/
├── package.json
├── prisma/
│   └── schema.prisma
├── src/
│   ├── index.js                     # Entry point
│   ├── services/
│   │   ├── presenceService.js       # Lógica principal
│   │   └── chatwootApiService.js    # ⭐ Chamar API Chatwoot
│   ├── config/
│   │   └── constants.js             # Configurações
│   └── utils/
│       └── logger.js                # Logging
└── .env
```

---

### 1. `package.json`

```json
{
  "name": "chatwoot-presence-automation",
  "version": "1.0.0",
  "description": "External presence automation for Chatwoot account_id=1",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js"
  },
  "dependencies": {
    "@prisma/client": "^5.0.0",
    "ioredis": "^5.3.0",
    "winston": "^3.11.0"
  },
  "devDependencies": {
    "prisma": "^5.0.0",
    "nodemon": "^3.0.0"
  }
}
```

---

### 2. `.env`

```env
# Database (apenas leitura para buscar mensagens)
DATABASE_URL="postgresql://user:password@localhost:5432/chatwoot_production"

# Chatwoot API
CHATWOOT_URL="https://seu-chatwoot.com"
CHATWOOT_API_TOKEN="SEU_API_ACCESS_TOKEN_AQUI"

# Configurações
ACCOUNT_ID=1
CHECK_INTERVAL_MS=20000          # 20 segundos
INACTIVITY_TIMEOUT_MIN=10        # 10 minutos sem mensagem → offline
BUSY_TIMEOUT_HOURS=3             # 3 horas em busy → offline
LOG_LEVEL=info
```

---

### 3. `src/config/constants.js`

```javascript
module.exports = {
  ACCOUNT_ID: parseInt(process.env.ACCOUNT_ID || '1', 10),
  CHECK_INTERVAL_MS: parseInt(process.env.CHECK_INTERVAL_MS || '20000', 10),
  INACTIVITY_TIMEOUT_MIN: parseInt(process.env.INACTIVITY_TIMEOUT_MIN || '10', 10),
  BUSY_TIMEOUT_HOURS: parseInt(process.env.BUSY_TIMEOUT_HOURS || '3', 10),

  // Status values
  STATUS: {
    ONLINE: 'online',
    OFFLINE: 'offline',
    BUSY: 'busy',
  },

  // Message types
  MESSAGE_TYPE: {
    INCOMING: 0,
    OUTGOING: 1,
    ACTIVITY: 2,
  },

  // Sender types
  SENDER_TYPE: {
    USER: 'User',
    CONTACT: 'Contact',
  },
};
```

---

### 4. `src/utils/logger.js`

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.printf(
          ({ level, message, timestamp, ...meta }) =>
            `${timestamp} [${level}]: ${message} ${
              Object.keys(meta).length ? JSON.stringify(meta) : ''
            }`
        )
      ),
    }),
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
  ],
});

module.exports = logger;
```

---

### 5. `src/services/chatwootApiService.js` ⭐ NOVO!

```javascript
const axios = require('axios');
const logger = require('../utils/logger');

class ChatwootApiService {
  constructor() {
    this.baseURL = process.env.CHATWOOT_URL || 'http://localhost:3000';
    this.apiToken = process.env.CHATWOOT_API_TOKEN;

    if (!this.apiToken) {
      throw new Error('CHATWOOT_API_TOKEN is required in .env');
    }

    this.client = axios.create({
      baseURL: this.baseURL,
      headers: {
        'api_access_token': this.apiToken,
        'Content-Type': 'application/json',
      },
    });
  }

  /**
   * Atualizar availability de um agente via API Chatwoot
   *
   * Vantagens:
   * - Dispara callbacks Rails (Redis sincronizado automaticamente)
   * - WebSocket broadcast funciona
   * - Validações aplicadas
   * - Auditoria completa
   */
  async updateAgentAvailability(userId, accountId, availability) {
    try {
      // Primeiro, precisamos fazer a requisição no contexto do usuário
      // Endpoint: POST /api/v1/profile/availability
      // Mas esse endpoint só funciona para o próprio usuário logado!

      // ⚠️ PROBLEMA: API /profile/availability só atualiza o usuário autenticado
      // Não há endpoint público para atualizar availability de OUTRO usuário

      // SOLUÇÃO: Usar endpoint interno ou criar custom endpoint
      // Por enquanto, retornar erro
      logger.error(
        `API limitation: Cannot update availability for user ${userId} via public API`
      );
      return false;
    } catch (error) {
      logger.error(
        `Failed to update availability for user ${userId}:`,
        error.message
      );
      return false;
    }
  }
}

module.exports = new ChatwootApiService();
```

**⚠️ IMPORTANTE: Limitação da API**

O endpoint `/api/v1/profile/availability` só funciona para atualizar o **próprio usuário autenticado**.

**Não há endpoint público** para admin atualizar availability de outros usuários!

**Soluções**:

#### Opção A: Criar Custom Endpoint (Recomendado)

Adicionar no Chatwoot:

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    namespace :accounts do
      resource :account, only: [] do
        resources :agents, only: [] do
          member do
            post :update_availability  # ← NOVO!
          end
        end
      end
    end
  end
end
```

```ruby
# app/controllers/api/v1/accounts/agents_controller.rb
def update_availability
  agent_user = AccountUser.find_by!(
    account_id: Current.account.id,
    user_id: params[:id]
  )

  agent_user.update!(availability: permitted_params[:availability])

  head :ok
end

private

def permitted_params
  params.permit(:availability)
end
```

**Usar**:
```bash
POST /api/v1/accounts/1/agents/50/update_availability
{
  "availability": "online"
}
```

#### Opção B: DB Direto + Redis Manual (Código já fornecido)

Ver seção "redisService.js" abaixo.

---

### 6. `src/services/presenceService.js`

```javascript
const { PrismaClient } = require('@prisma/client');
const logger = require('../utils/logger');
const {
  ACCOUNT_ID,
  INACTIVITY_TIMEOUT_MIN,
  BUSY_TIMEOUT_HOURS,
  STATUS,
  MESSAGE_TYPE,
  SENDER_TYPE,
} = require('../config/constants');

const prisma = new PrismaClient();

class PresenceService {
  /**
   * Buscar última mensagem OUTGOING enviada por um agente
   */
  async getLastOutgoingMessage(userId) {
    return prisma.message.findFirst({
      where: {
        accountId: ACCOUNT_ID,
        senderId: userId,
        senderType: SENDER_TYPE.USER,
        messageType: MESSAGE_TYPE.OUTGOING,
      },
      orderBy: {
        createdAt: 'desc',
      },
      select: {
        id: true,
        createdAt: true,
      },
    });
  }

  /**
   * Calcular há quantos minutos foi enviada a última mensagem
   */
  getMinutesSinceMessage(messageCreatedAt) {
    if (!messageCreatedAt) return Infinity;

    const now = new Date();
    const diffMs = now - new Date(messageCreatedAt);
    return Math.floor(diffMs / 1000 / 60);
  }

  /**
   * Calcular há quantas horas está no status atual
   */
  getHoursSinceStatusChange(updatedAt) {
    if (!updatedAt) return 0;

    const now = new Date();
    const diffMs = now - new Date(updatedAt);
    return diffMs / 1000 / 60 / 60;
  }

  /**
   * Determinar novo status baseado em regras
   */
  determineNewStatus(accountUser, lastMessage) {
    const currentStatus = accountUser.availability;
    const minutesSinceMessage = this.getMinutesSinceMessage(
      lastMessage?.createdAt
    );
    const hoursSinceUpdate = this.getHoursSinceStatusChange(
      accountUser.updatedAt
    );

    // REGRA 1: Se enviou mensagem recentemente (< 10 min) → ONLINE
    if (minutesSinceMessage < INACTIVITY_TIMEOUT_MIN) {
      return STATUS.ONLINE;
    }

    // REGRA 2: Se está em BUSY há mais de 3 horas → OFFLINE
    if (
      currentStatus === STATUS.BUSY &&
      hoursSinceUpdate >= BUSY_TIMEOUT_HOURS
    ) {
      logger.info(
        `User ${accountUser.userId} in BUSY for ${hoursSinceUpdate.toFixed(1)}h → forcing OFFLINE`
      );
      return STATUS.OFFLINE;
    }

    // REGRA 3: Se está em BUSY e < 3h → Manter BUSY
    if (currentStatus === STATUS.BUSY) {
      return STATUS.BUSY; // Não mexe
    }

    // REGRA 4: Se não enviou mensagem há 10+ min → OFFLINE
    if (minutesSinceMessage >= INACTIVITY_TIMEOUT_MIN) {
      return STATUS.OFFLINE;
    }

    // Fallback: Manter status atual
    return currentStatus;
  }

  /**
   * Processar todos os agentes da account_id = 1
   */
  async processAgents() {
    try {
      const accountUsers = await prisma.accountUser.findMany({
        where: {
          accountId: ACCOUNT_ID,
          autoOffline: false, // Apenas agentes com auto_offline=false
        },
        include: {
          user: {
            select: {
              id: true,
              name: true,
              email: true,
            },
          },
        },
      });

      logger.info(
        `Processing ${accountUsers.length} agents for account ${ACCOUNT_ID}`
      );

      const updates = [];

      for (const accountUser of accountUsers) {
        const lastMessage = await this.getLastOutgoingMessage(
          accountUser.userId
        );
        const newStatus = this.determineNewStatus(accountUser, lastMessage);

        // Só atualiza se status mudou
        if (newStatus !== accountUser.availability) {
          const minutesSinceMessage = this.getMinutesSinceMessage(
            lastMessage?.createdAt
          );

          logger.info(
            `User ${accountUser.user.name} (${accountUser.user.email}): ${accountUser.availability} → ${newStatus} (last message ${minutesSinceMessage} min ago)`
          );

          // ⚠️ IMPORTANTE: Atualizar DB + Redis
          // Redis DEVE ser atualizado porque callback Rails não dispara via Prisma
          updates.push(
            (async () => {
              // 1. Atualizar DB
              await prisma.accountUser.update({
                where: { id: accountUser.id },
                data: { availability: newStatus },
              });

              // 2. Atualizar Redis (CRÍTICO para WebSocket broadcast)
              const redisService = require('./redisService');
              await redisService.setStatus(accountUser.userId, newStatus);
            })()
          );
        }
      }

      // Executar todas as atualizações em paralelo
      if (updates.length > 0) {
        await Promise.all(updates);
        logger.info(`Updated ${updates.length} agents`);
      } else {
        logger.debug('No status changes needed');
      }

      return {
        processed: accountUsers.length,
        updated: updates.length,
      };
    } catch (error) {
      logger.error('Error processing agents:', error);
      throw error;
    }
  }

  /**
   * Cleanup (disconnect Prisma)
   */
  async cleanup() {
    await prisma.$disconnect();
  }
}

module.exports = new PresenceService();
```

---

### 6. `src/services/redisService.js` (⚠️ OBRIGATÓRIO!)

**⚠️ IMPORTANTE: Você PRECISA atualizar Redis!**

Quando você atualiza `account_users.availability` via Prisma, o **Rails callback** `after_save :update_presence_in_redis` **NÃO dispara** (porque está fora do Rails).

**Problema**:
1. Você atualiza `availability` no DB ✅
2. Callback Rails NÃO dispara ❌
3. Redis `ONLINE_STATUS::1` fica desatualizado ❌
4. WebSocket broadcast lê Redis → Envia status errado para UI ❌

**Solução**: Atualizar Redis manualmente no Node.js:

```javascript
const Redis = require('ioredis');
const logger = require('../utils/logger');
const { ACCOUNT_ID } = require('../config/constants');

class RedisService {
  constructor() {
    this.redis = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');
  }

  /**
   * Atualizar status no Redis (equivalente ao OnlineStatusTracker.set_status)
   */
  async setStatus(userId, status) {
    const key = `ONLINE_STATUS::${ACCOUNT_ID}`;
    await this.redis.hset(key, userId.toString(), status);
    logger.debug(`Redis updated: ${key} -> ${userId}: ${status}`);
  }

  /**
   * Limpar presença (opcional, se quiser forçar "offline" no heartbeat também)
   */
  async removePresence(userId) {
    const key = `ONLINE_PRESENCE::${ACCOUNT_ID}::USERS`;
    await this.redis.zrem(key, userId.toString());
    logger.debug(`Redis presence removed: ${key} -> ${userId}`);
  }

  /**
   * Cleanup
   */
  async cleanup() {
    await this.redis.quit();
  }
}

module.exports = new RedisService();
```

**✅ JÁ INCLUÍDO no código do `presenceService.js` acima!**

O código já faz:
1. Atualizar DB via Prisma
2. Atualizar Redis via `redisService.setStatus()`

Isso garante que **WebSocket broadcast** sempre envia status correto para UI.

---

### 7. `src/index.js` (Entry Point)

```javascript
const presenceService = require('./services/presenceService');
const logger = require('./utils/logger');
const { CHECK_INTERVAL_MS, ACCOUNT_ID } = require('./config/constants');

let intervalId;

async function runJob() {
  try {
    logger.info('Running presence automation job...');
    const result = await presenceService.processAgents();
    logger.info(
      `Job completed: ${result.processed} processed, ${result.updated} updated`
    );
  } catch (error) {
    logger.error('Job failed:', error);
  }
}

async function start() {
  logger.info('=' .repeat(60));
  logger.info('Chatwoot Presence Automation Starting...');
  logger.info(`Account ID: ${ACCOUNT_ID}`);
  logger.info(`Interval: ${CHECK_INTERVAL_MS}ms (${CHECK_INTERVAL_MS / 1000}s)`);
  logger.info('=' .repeat(60));

  // Run immediately on start
  await runJob();

  // Then run every CHECK_INTERVAL_MS
  intervalId = setInterval(runJob, CHECK_INTERVAL_MS);
}

async function shutdown() {
  logger.info('Shutting down gracefully...');

  if (intervalId) {
    clearInterval(intervalId);
  }

  await presenceService.cleanup();
  logger.info('Shutdown complete');
  process.exit(0);
}

// Handle signals
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

// Start the service
start().catch((error) => {
  logger.error('Failed to start:', error);
  process.exit(1);
});
```

---

## Execução

### 1. Instalar Dependências

```bash
npm install
```

---

### 2. Gerar Cliente Prisma

```bash
npx prisma generate
```

---

### 3. Testar Conexão

```bash
npx prisma db pull  # Verificar se conecta no DB
```

---

### 4. Rodar Localmente (Dev)

```bash
npm run dev
```

**Output esperado**:
```
2025-11-21 15:00:00 [info]: ============================================================
2025-11-21 15:00:00 [info]: Chatwoot Presence Automation Starting...
2025-11-21 15:00:00 [info]: Account ID: 1
2025-11-21 15:00:00 [info]: Interval: 20000ms (20s)
2025-11-21 15:00:00 [info]: ============================================================
2025-11-21 15:00:00 [info]: Running presence automation job...
2025-11-21 15:00:01 [info]: Processing 33 agents for account 1
2025-11-21 15:00:02 [info]: User Alane (alanealmeida2022@gmail.com): offline → online (last message 2 min ago)
2025-11-21 15:00:02 [info]: User Patricia (patybarcelos466@gmail.com): online → offline (last message 15 min ago)
2025-11-21 15:00:03 [info]: Updated 2 agents
2025-11-21 15:00:03 [info]: Job completed: 33 processed, 2 updated
```

---

### 5. Rodar em Produção (PM2)

```bash
# Instalar PM2
npm install -g pm2

# Iniciar serviço
pm2 start src/index.js --name chatwoot-presence

# Ver logs
pm2 logs chatwoot-presence

# Status
pm2 status

# Restart
pm2 restart chatwoot-presence

# Stop
pm2 stop chatwoot-presence

# Salvar configuração (auto-start on reboot)
pm2 save
pm2 startup
```

---

### 6. Rodar com Docker (Opcional)

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --production

COPY prisma ./prisma
RUN npx prisma generate

COPY src ./src

CMD ["node", "src/index.js"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  presence-automation:
    build: .
    restart: always
    env_file:
      - .env
    volumes:
      - ./logs:/app/logs
    depends_on:
      - postgres  # Se estiver no mesmo docker-compose do Chatwoot
```

```bash
docker-compose up -d
docker-compose logs -f presence-automation
```

---

## Regras de Negócio Detalhadas

### Fluxo de Decisão

```
┌─────────────────────────────────────────────────────────┐
│ Para cada agente (account_id=1, auto_offline=false):   │
└─────────────────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────────────────┐
│ 1. Buscar última mensagem OUTGOING do agente           │
└─────────────────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────────────────┐
│ 2. Calcular tempo desde última mensagem                │
└─────────────────────────────────────────────────────────┘
           ↓
      ┌────┴────┐
      │ < 10min? │
      └────┬────┘
           │
    ┌──────┴──────┐
    │ SIM         │ NÃO
    ↓             ↓
┌─────────┐   ┌───────────────────┐
│ ONLINE  │   │ Qual status atual?│
└─────────┘   └───────────────────┘
                      ↓
              ┌───────┴───────┐
              │ BUSY?         │
              └───────┬───────┘
                      │
              ┌───────┴───────┐
              │ SIM           │ NÃO
              ↓               ↓
      ┌───────────────┐   ┌─────────┐
      │ BUSY há 3+h?  │   │ OFFLINE │
      └───────┬───────┘   └─────────┘
              │
      ┌───────┴───────┐
      │ SIM           │ NÃO
      ↓               ↓
  ┌─────────┐   ┌──────────────┐
  │ OFFLINE │   │ Manter BUSY  │
  └─────────┘   └──────────────┘
```

---

### Exemplos Práticos

#### Cenário 1: Agente Ativo
```
10:00 - Agente envia mensagem
10:05 - Job roda: "última mensagem há 5 min" → ONLINE ✅
10:25 - Job roda: "última mensagem há 25 min" → OFFLINE ❌
```

---

#### Cenário 2: Agente vai para Pausa
```
10:00 - Agente envia mensagem → ONLINE
10:15 - Agente muda status manualmente para BUSY (vai almoçar)
10:35 - Job roda: "BUSY há 20 min, última msg há 35 min" → Manter BUSY ✅
11:00 - Job roda: "BUSY há 45 min" → Manter BUSY ✅
13:30 - Job roda: "BUSY há 3h 15min" → OFFLINE ❌ (esqueceu de voltar)
```

---

#### Cenário 3: Agente Volta da Pausa
```
13:35 - Agente envia mensagem
13:36 - Job roda: "última mensagem há 1 min" → ONLINE ✅ (mesmo que estivesse OFFLINE)
```

---

#### Cenário 4: Agente Muda para Busy Temporário (Banheiro)
```
14:00 - Agente envia mensagem → ONLINE
14:05 - Agente muda para BUSY (banheiro rápido)
14:12 - Job roda: "BUSY há 7 min" → Manter BUSY ✅
14:15 - Agente volta, envia mensagem
14:16 - Job roda: "última mensagem há 1 min" → ONLINE ✅
```

---

## Monitoramento e Debugging

### 1. Ver Status em Tempo Real

```javascript
// src/scripts/check-status.js
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function checkStatus() {
  const accountUsers = await prisma.accountUser.findMany({
    where: {
      accountId: 1,
      autoOffline: false,
    },
    include: {
      user: {
        select: {
          name: true,
          email: true,
        },
      },
    },
  });

  console.log('STATUS | NAME | EMAIL | UPDATED AT');
  console.log('-'.repeat(80));

  for (const au of accountUsers) {
    console.log(
      `${au.availability.padEnd(7)} | ${au.user.name.padEnd(20)} | ${au.user.email.padEnd(30)} | ${au.updatedAt.toISOString()}`
    );
  }

  await prisma.$disconnect();
}

checkStatus();
```

**Executar**:
```bash
node src/scripts/check-status.js
```

---

### 2. Ver Última Mensagem de Cada Agente

```javascript
// src/scripts/check-last-messages.js
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function checkLastMessages() {
  const users = await prisma.user.findMany({
    where: {
      accountUsers: {
        some: {
          accountId: 1,
          autoOffline: false,
        },
      },
    },
    select: {
      id: true,
      name: true,
      email: true,
    },
  });

  console.log('NAME | EMAIL | LAST MESSAGE | MINUTES AGO');
  console.log('-'.repeat(100));

  for (const user of users) {
    const lastMessage = await prisma.message.findFirst({
      where: {
        accountId: 1,
        senderId: user.id,
        senderType: 'User',
        messageType: 1, // OUTGOING
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    const minutesAgo = lastMessage
      ? Math.floor((Date.now() - new Date(lastMessage.createdAt)) / 60000)
      : 'NEVER';

    const lastMsgTime = lastMessage
      ? lastMessage.createdAt.toISOString()
      : 'NEVER';

    console.log(
      `${user.name.padEnd(20)} | ${user.email.padEnd(35)} | ${lastMsgTime.padEnd(25)} | ${minutesAgo}`
    );
  }

  await prisma.$disconnect();
}

checkLastMessages();
```

---

### 3. Simular Processamento (Dry Run)

Modificar `presenceService.js` para adicionar modo dry-run:

```javascript
// src/services/presenceService.js

async function processAgents(dryRun = false) {
  // ... código existente ...

  for (const accountUser of accountUsers) {
    const lastMessage = await this.getLastOutgoingMessage(accountUser.userId);
    const newStatus = this.determineNewStatus(accountUser, lastMessage);

    if (newStatus !== accountUser.availability) {
      const minutesSinceMessage = this.getMinutesSinceMessage(
        lastMessage?.createdAt
      );

      logger.info(
        `${dryRun ? '[DRY RUN] ' : ''}User ${accountUser.user.name}: ${accountUser.availability} → ${newStatus} (last message ${minutesSinceMessage} min ago)`
      );

      if (!dryRun) {
        updates.push(
          prisma.accountUser.update({
            where: { id: accountUser.id },
            data: { availability: newStatus },
          })
        );
      }
    }
  }

  // ...
}
```

**Script de teste**:
```javascript
// src/scripts/dry-run.js
const presenceService = require('../services/presenceService');

(async () => {
  await presenceService.processAgents(true); // dry-run mode
  await presenceService.cleanup();
})();
```

---

## FAQ

### Q: O que acontece se a automação Node.js parar?

**R**:
- Chatwoot continua funcionando normalmente
- Agentes **NÃO** mudam de status (ficam no último estado)
- `auto_offline=false` → Chatwoot ignora heartbeat, usa DB
- Status fica "congelado" até automação voltar

**Solução**: Usar PM2 ou Docker com `restart: always`

---

### Q: Redis vai conflitar com minha automação?

**R**: **PARCIALMENTE - Precisa sincronizar!**

**O que funciona**:
- API endpoints leem de `availability` (DB) → Ignora Redis ✅
- `auto_offline=false` → Chatwoot ignora `ONLINE_PRESENCE` (heartbeat) ✅

**O que NÃO funciona**:
- WebSocket broadcast **LÊ Redis** `ONLINE_STATUS::1` ❌
- Se você atualizar só o DB, Redis fica stale ❌
- UI recebe status errado via WebSocket broadcast ❌

**Solução**:
- Sua automação Node.js DEVE atualizar **DB + Redis**
- Código fornecido já faz isso via `redisService.setStatus()`
- Controle total garantido! ✅

**Descoberta durante troubleshooting**:
Descobrimos essa inconsistência arquitetural quando usamos `update_all(auto_offline: false)` em produção. Redis ficou desatualizado porque callback Rails não disparou. WebSocket broadcast continuou enviando status stale do Redis, mesmo com `auto_offline=false`.

---

### Q: E se agente mudar status manualmente na UI?

**R**: Funciona perfeitamente!
- Agente clica "Busy" na UI → `availability = 'busy'` no DB
- Próximo job (20s depois) → Detecta `currentStatus = 'busy'`
- **Regra 3**: Se BUSY há < 3h → Manter BUSY ✅
- Agente envia mensagem → Automação muda para ONLINE (sobrescreve)

**Fluxo**:
```
10:00 - Agente clica "Busy" na UI
10:20 - Job roda: "BUSY há 20 min, sem mensagens" → Manter BUSY ✅
10:25 - Agente envia mensagem (esqueceu de voltar pra online)
10:26 - Job roda: "última msg há 1 min" → ONLINE ✅ (automático)
```

---

### Q: Como testar sem afetar produção?

**R**:
1. **Modo dry-run** (script acima)
2. **Testar com apenas 1 agente**:
   ```javascript
   // presenceService.js
   const accountUsers = await prisma.accountUser.findMany({
     where: {
       accountId: ACCOUNT_ID,
       autoOffline: false,
       userId: 50, // ← ID da Alane (teste)
     },
     // ...
   });
   ```
3. **Logs detalhados**: Aumentar `LOG_LEVEL=debug` no `.env`

---

### Q: Performance com 33 agentes?

**R**:
- 33 queries (`getLastOutgoingMessage`) + 33 reads
- Total: ~66 queries a cada 20 segundos
- **< 100ms** em DB PostgreSQL bem configurado
- Usa índices: `(sender_id, sender_type, created_at DESC)`

**Otimização** (se precisar):
```javascript
// Buscar todas as últimas mensagens de uma vez
async getLastOutgoingMessages(userIds) {
  const messages = await prisma.$queryRaw`
    SELECT DISTINCT ON (sender_id)
      sender_id,
      created_at
    FROM messages
    WHERE account_id = ${ACCOUNT_ID}
      AND sender_id = ANY(${userIds})
      AND sender_type = 'User'
      AND message_type = 1
    ORDER BY sender_id, created_at DESC
  `;

  return messages.reduce((acc, msg) => {
    acc[msg.sender_id] = msg;
    return acc;
  }, {});
}
```

---

## Conclusão

### ✅ Solução Completa

1. **Ignorar heartbeat**: `auto_offline = false` para account_id=1
2. **Controle por atividade**: Última mensagem enviada
3. **Respeitar pausa**: BUSY não muda para offline (exceto 3+h)
4. **Job 24/7**: A cada 20 segundos
5. **Sem conflito com Redis**: Chatwoot ignora presence quando auto_offline=false

### 📊 Arquitetura Final

```
┌─────────────────────────────────────────────────────────┐
│              CHATWOOT (Rails + Redis)                   │
│                                                         │
│  - WebSocket heartbeat continua funcionando            │
│  - Redis ONLINE_PRESENCE atualizado (IGNORADO)         │
│  - Redis ONLINE_STATUS sincronizado (opcional)         │
│  - Lê de account_users.availability (DB) ✅            │
└─────────────────────────────────────────────────────────┘
                         ↑
                         │ Atualiza DB
                         │
┌─────────────────────────────────────────────────────────┐
│         NODE.JS AUTOMATION (Prisma)                     │
│                                                         │
│  Job a cada 20s:                                        │
│  1. Buscar última mensagem OUTGOING de cada agente      │
│  2. Calcular tempo desde última mensagem               │
│  3. Aplicar regras:                                     │
│     - < 10 min → ONLINE                                 │
│     - BUSY < 3h → Manter BUSY                           │
│     - BUSY ≥ 3h → OFFLINE                              │
│     - Sem mensagem ≥ 10min → OFFLINE                   │
│  4. Atualizar account_users.availability               │
└─────────────────────────────────────────────────────────┘
```

### 🚀 Próximos Passos

1. ✅ Configurar `auto_offline=false` para account_id=1
2. ✅ Implementar Node.js service (código acima)
3. ✅ Testar em dry-run mode
4. ✅ Deploy com PM2 ou Docker
5. ✅ Monitorar logs por 24h
6. ✅ Ajustar parâmetros se necessário (10min, 3h, etc.)
