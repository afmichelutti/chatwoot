# Architecture Research

**Domain:** Multi-tenant SaaS customer support platform (Next.js frontend + Chatwoot backend)
**Researched:** 2026-02-11
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Next.js Frontend Layer                          │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │  Dashboard   │  │  Inbox UI    │  │  Settings    │              │
│  │  Components  │  │  Components  │  │  Components  │              │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘              │
│         │                  │                  │                      │
├─────────┴──────────────────┴──────────────────┴──────────────────────┤
│                      Server Components Layer                         │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │           Data Access Layer (DAL) - Server Actions          │    │
│  └────────────────────────┬────────────────────────────────────┘    │
├───────────────────────────┼──────────────────────────────────────────┤
│         Backend-for-Frontend (BFF) - API Routes Layer               │
│  ┌──────────────┬─────────┴────────┬───────────────┐               │
│  │  Auth Proxy  │  Chatwoot Proxy  │  WebSocket    │               │
│  │  /api/auth   │  /api/chatwoot   │  Relay        │               │
│  └──────┬───────┴─────────┬────────┴───────┬───────┘               │
├─────────┼─────────────────┼────────────────┼───────────────────────┤
│         │                 │                │                        │
│    ┌────┴────┐       ┌────┴────┐      ┌────┴────┐                 │
│    │ Prisma  │       │ Chatwoot│      │ActionCable                 │
│    │ Client  │       │ API SDK │      │ Client   │                 │
│    └────┬────┘       └────┬────┘      └────┬────┘                 │
└─────────┼─────────────────┼────────────────┼───────────────────────┘
          │                 │                │
          ▼                 ▼                ▼
┌─────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  PostgreSQL     │  │  Chatwoot REST   │  │  Chatwoot WS     │
│  (Prisma DB)    │  │  API v1/v2       │  │  (ActionCable)   │
│                 │  │                  │  │                  │
│  - Tenants      │  │  - Conversations │  │  - Live updates  │
│  - White-label  │  │  - Messages      │  │  - Typing status │
│  - CRM Data     │  │  - Contacts      │  │  - New messages  │
│  - Analytics    │  │  - Inboxes       │  │                  │
└─────────────────┘  └──────────────────┘  └──────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **Next.js App Router** | Frontend rendering, routing, server components | React Server Components (RSC) for initial page loads, client components for interactivity |
| **Data Access Layer (DAL)** | Centralized data operations, session management, authorization | Server-side only functions with session verification |
| **BFF API Routes** | Proxy to Chatwoot, auth token management, request transformation | Next.js Route Handlers (`app/api/*/route.ts`) |
| **Auth Proxy** | Handle own auth + Chatwoot token mapping | Session cookies + Chatwoot API access tokens |
| **Chatwoot Proxy** | Forward requests to Chatwoot with proper auth headers | Axios/fetch with token injection |
| **WebSocket Relay** | Relay ActionCable events to frontend | Separate Node.js service or Next.js custom server |
| **Prisma Client** | ORM for tenant/CRM/analytics data | Connection pooling, multi-tenant context |
| **Chatwoot API SDK** | Type-safe wrapper for Chatwoot REST API | Generated or hand-written TypeScript SDK |

## Recommended Project Structure

```
chatwize/
├── app/
│   ├── (auth)/                     # Auth route group
│   │   ├── login/
│   │   └── signup/
│   ├── (dashboard)/                # Protected route group
│   │   ├── [tenantId]/            # Tenant-scoped routes
│   │   │   ├── inbox/
│   │   │   ├── contacts/
│   │   │   ├── analytics/
│   │   │   └── settings/
│   │   └── layout.tsx             # Dashboard layout with tenant context
│   ├── api/
│   │   ├── auth/
│   │   │   ├── login/route.ts     # Own auth endpoint
│   │   │   ├── logout/route.ts
│   │   │   └── session/route.ts
│   │   ├── chatwoot/
│   │   │   ├── proxy/route.ts     # Generic Chatwoot proxy
│   │   │   ├── conversations/route.ts
│   │   │   ├── messages/route.ts
│   │   │   └── contacts/route.ts
│   │   ├── webhooks/
│   │   │   └── chatwoot/route.ts  # Chatwoot webhooks
│   │   └── ws/                     # WebSocket setup
│   └── layout.tsx
├── lib/
│   ├── auth/
│   │   ├── session.ts             # Session management (iron-session/jose)
│   │   ├── chatwoot-token.ts      # Chatwoot token mapping
│   │   └── middleware.ts          # Auth middleware helpers
│   ├── dal/
│   │   ├── tenant.ts              # Tenant data access
│   │   ├── user.ts                # User data access
│   │   ├── crm.ts                 # CRM data access
│   │   └── analytics.ts           # Analytics data access
│   ├── chatwoot/
│   │   ├── client.ts              # Chatwoot API client
│   │   ├── types.ts               # Chatwoot TypeScript types
│   │   └── webhooks.ts            # Webhook handlers
│   ├── prisma/
│   │   ├── client.ts              # Prisma client singleton
│   │   └── middleware.ts          # Multi-tenant middleware
│   └── websocket/
│       ├── client.ts              # ActionCable client
│       └── relay.ts               # WebSocket relay logic
├── components/
│   ├── inbox/                      # Inbox components
│   ├── contacts/                   # Contact components
│   └── shared/                     # Shared UI components
├── prisma/
│   └── schema.prisma              # Prisma schema
├── ws-server/                      # Separate WebSocket server (optional)
│   ├── index.ts
│   └── Dockerfile
├── proxy.ts                        # Next.js 16+ proxy (auth checks)
└── package.json
```

### Structure Rationale

- **`(auth)` and `(dashboard)` route groups:** Clean separation of public vs protected routes without affecting URL structure
- **`[tenantId]` dynamic route:** All tenant-scoped features under a single route parameter for easy context extraction
- **`app/api/chatwoot/proxy`:** Generic proxy route that forwards any Chatwoot API call with auth headers
- **`lib/dal/`:** Data Access Layer isolates all database operations, enforces authorization, prevents data leakage
- **`lib/chatwoot/`:** Centralized Chatwoot integration logic, easy to mock for testing
- **`ws-server/`:** Optional separate WebSocket service for production deployments (not needed for self-hosted with custom server)

## Architectural Patterns

### Pattern 1: Backend-for-Frontend (BFF) Proxy

**What:** Next.js API Routes act as a proxy layer between the frontend and Chatwoot API, handling authentication, request transformation, and response aggregation.

**When to use:** Always - essential for hiding Chatwoot API credentials, managing token refresh, and providing a unified API contract to the frontend.

**Trade-offs:**
- ✅ Security: API keys never exposed to client
- ✅ Flexibility: Can aggregate multiple Chatwoot endpoints
- ✅ Caching: Can add CDN caching with proper headers
- ❌ Latency: Adds one network hop
- ❌ Complexity: More code to maintain

**Example:**
```typescript
// app/api/chatwoot/conversations/route.ts
import { NextRequest } from 'next/server'
import { verifySession } from '@/lib/dal/session'
import { getChatwootToken } from '@/lib/auth/chatwoot-token'
import { chatwootClient } from '@/lib/chatwoot/client'

export async function GET(request: NextRequest) {
  // 1. Verify user session
  const session = await verifySession()
  if (!session) {
    return new Response(null, { status: 401 })
  }

  // 2. Get tenant context and Chatwoot token
  const tenantId = request.nextUrl.searchParams.get('tenantId')
  const chatwootToken = await getChatwootToken(session.userId, tenantId)

  // 3. Forward request to Chatwoot
  const conversations = await chatwootClient.getConversations(chatwootToken, {
    accountId: session.chatwootAccountId
  })

  // 4. Return response
  return Response.json(conversations)
}
```

### Pattern 2: Multi-Tenant Context Middleware

**What:** Prisma middleware that automatically injects tenant context into all database queries, ensuring data isolation.

**When to use:** Always in multi-tenant SaaS - prevents data leakage across tenants.

**Trade-offs:**
- ✅ Security: Automatic tenant isolation
- ✅ DX: No need to manually add tenant filters
- ❌ Performance: Slight overhead on every query
- ❌ Debugging: Can be confusing when queries don't return expected data

**Example:**
```typescript
// lib/prisma/middleware.ts
import { Prisma } from '@prisma/client'

export function createTenantMiddleware(tenantId: string): Prisma.Middleware {
  return async (params, next) => {
    // Add tenant filter to all queries
    if (params.model && ['Contact', 'CrmDeal', 'Analytics'].includes(params.model)) {
      if (params.action === 'findMany' || params.action === 'findFirst') {
        params.args.where = {
          ...params.args.where,
          tenantId,
        }
      }
    }

    return next(params)
  }
}

// Usage in DAL
import { prisma } from '@/lib/prisma/client'
import { createTenantMiddleware } from '@/lib/prisma/middleware'

export async function getContacts(tenantId: string) {
  const client = prisma.$extends({
    query: {
      $allModels: createTenantMiddleware(tenantId)
    }
  })

  return client.contact.findMany() // Automatically filtered by tenantId
}
```

### Pattern 3: Session-Based Auth with Chatwoot Token Mapping

**What:** Own authentication layer that maps internal user sessions to Chatwoot API access tokens per tenant.

**When to use:** When you need custom auth logic (white-label, custom pricing, CRM data) but must integrate with Chatwoot's per-account system.

**Trade-offs:**
- ✅ Flexibility: Full control over auth flow
- ✅ Multi-tenant: One user can access multiple tenant accounts
- ✅ White-label: Custom login pages per tenant
- ❌ Complexity: Must manage two auth systems
- ❌ Token refresh: Need to handle Chatwoot token expiration

**Example:**
```typescript
// lib/auth/chatwoot-token.ts
import { prisma } from '@/lib/prisma/client'

export async function getChatwootToken(
  userId: string,
  tenantId: string
): Promise<string> {
  // 1. Get user-tenant relationship
  const membership = await prisma.tenantMembership.findUnique({
    where: {
      userId_tenantId: { userId, tenantId }
    },
    include: {
      tenant: true
    }
  })

  if (!membership) {
    throw new Error('User not member of tenant')
  }

  // 2. Check if token is still valid
  if (membership.chatwootTokenExpiry > new Date()) {
    return membership.chatwootAccessToken
  }

  // 3. Refresh token from Chatwoot
  const newToken = await refreshChatwootToken(
    membership.tenant.chatwootAccountId,
    membership.chatwootRefreshToken
  )

  // 4. Update in database
  await prisma.tenantMembership.update({
    where: { id: membership.id },
    data: {
      chatwootAccessToken: newToken.accessToken,
      chatwootRefreshToken: newToken.refreshToken,
      chatwootTokenExpiry: newToken.expiresAt
    }
  })

  return newToken.accessToken
}
```

### Pattern 4: WebSocket Relay for Real-Time Updates

**What:** Separate service that maintains persistent WebSocket connections to Chatwoot ActionCable and relays events to Next.js frontend via SSE or WebSocket.

**When to use:** When deploying to serverless (Vercel) or when Next.js app needs to scale horizontally without maintaining persistent connections.

**Trade-offs:**
- ✅ Scalability: Next.js can be serverless
- ✅ Separation: WebSocket concerns isolated
- ❌ Infrastructure: Additional service to deploy
- ❌ Complexity: Cross-service communication

**Example:**
```typescript
// ws-server/index.ts (separate Node.js service)
import ActionCable from '@rails/actioncable'
import { createServer } from 'http'
import { Server } from 'socket.io'

const server = createServer()
const io = new Server(server, {
  cors: { origin: process.env.NEXT_PUBLIC_APP_URL }
})

io.on('connection', (socket) => {
  const { tenantId, chatwootToken } = socket.handshake.auth

  // Connect to Chatwoot ActionCable
  const cable = ActionCable.createConsumer(
    `${process.env.CHATWOOT_WS_URL}?access_token=${chatwootToken}`
  )

  const subscription = cable.subscriptions.create(
    { channel: 'RoomChannel', pubsub_token: tenantId },
    {
      received: (data) => {
        // Relay event to frontend
        socket.emit('chatwoot:event', data)
      }
    }
  )

  socket.on('disconnect', () => {
    subscription.unsubscribe()
    cable.disconnect()
  })
})

server.listen(3001)
```

```typescript
// lib/websocket/client.ts (Next.js frontend)
import { io } from 'socket.io-client'

export function connectToRelay(tenantId: string, token: string) {
  const socket = io(process.env.NEXT_PUBLIC_WS_RELAY_URL, {
    auth: { tenantId, chatwootToken: token }
  })

  socket.on('chatwoot:event', (event) => {
    // Handle real-time updates
    console.log('Received:', event)
  })

  return socket
}
```

## Data Flow

### Request Flow (Read Operations)

```
[User clicks "Open Inbox"]
    ↓
[Next.js Server Component] → verifySession() → DAL
    ↓ (session valid)
[Server Component] → getChatwootToken(userId, tenantId) → Prisma
    ↓ (token retrieved)
[Server Component] → fetch('/api/chatwoot/conversations?tenantId=X')
    ↓
[API Route Handler] → verifySession() → DAL
    ↓ (authorized)
[API Route] → chatwootClient.getConversations(token, accountId)
    ↓
[Chatwoot API] → Returns conversations JSON
    ↓
[API Route] → Response.json(conversations)
    ↓
[Server Component] → Renders inbox with data
```

### Request Flow (Write Operations)

```
[User sends message]
    ↓
[Client Component] → POST /api/chatwoot/messages
    ↓
[API Route Handler] → verifySession() → DAL
    ↓ (session valid)
[API Route] → getChatwootToken(userId, tenantId)
    ↓
[API Route] → chatwootClient.sendMessage(token, { content, conversationId })
    ↓
[Chatwoot API] → Creates message, triggers webhook
    ↓
[Chatwoot API] → Broadcasts via ActionCable
    ↓
[WebSocket Relay] → Receives ActionCable event
    ↓
[WebSocket Relay] → Emits to connected frontend clients
    ↓
[Client Component] → Updates UI optimistically + receives real-time confirmation
```

### State Management Flow

```
[Prisma Database] ←→ [DAL] ←→ [Server Components/Actions]
    ↓                              ↓
[Tenant Config]               [Chatwoot Token Store]
[White-label]                 [User-Tenant Mapping]
[CRM Data]
[Analytics]

[Chatwoot API] ←→ [BFF Proxy] ←→ [Server Components/Actions]
    ↓
[Conversations]
[Messages]
[Contacts]
[Inboxes]

[ActionCable WS] ←→ [WebSocket Relay] ←→ [Client Components]
    ↓
[Real-time events]
```

### Key Data Flows

1. **Authentication Flow:** User login → Create session → Map to Chatwoot token → Store in Prisma → Set session cookie
2. **Tenant Context Flow:** Request → Extract tenantId from route → Verify user access → Inject tenant context → Execute query
3. **Real-time Flow:** Chatwoot event → ActionCable → WebSocket Relay → Socket.IO → Frontend client → UI update
4. **CRM Enrichment Flow:** Chatwoot contact created → Webhook → Next.js API → Enrich with CRM data (Prisma) → Update Chatwoot via API

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| **0-1k users** | Single Next.js deployment (self-hosted with custom server), embedded WebSocket, single Prisma connection pool. Chatwoot self-hosted on same VPS. Simple and cost-effective. |
| **1k-10k users** | Separate WebSocket relay service (Docker container), Prisma connection pooling (external PgBouncer), Redis for session storage, CDN for static assets. Keep Next.js self-hosted or move to Vercel with custom WS service. |
| **10k-100k users** | Horizontal scaling of Next.js (load balancer), dedicated PostgreSQL instance for Prisma, Redis Cluster for sessions, dedicated WebSocket relay cluster (Socket.IO with Redis adapter), CDN caching for Chatwoot API responses (stale-while-revalidate), separate analytics database (read replicas). |
| **100k+ users** | Multi-region deployment (Next.js + WS relay), database sharding by tenant, Chatwoot could become bottleneck (consider enterprise plan or fork), implement GraphQL federation for API orchestration, dedicated message queue for async operations. |

### Scaling Priorities

1. **First bottleneck: Database connections (5k-10k users)**
   - **Problem:** Prisma connection pool exhaustion in serverless
   - **Solution:** External PgBouncer + adjust `connection_limit` in Prisma schema
   - **Example:** `postgresql://...?connection_limit=20&pgbouncer=true`

2. **Second bottleneck: WebSocket connections (10k-30k users)**
   - **Problem:** Single WebSocket relay can't handle connections
   - **Solution:** Socket.IO cluster mode with Redis adapter for horizontal scaling
   - **Monitoring:** Track connection count, CPU usage, memory per WS instance

3. **Third bottleneck: Chatwoot API rate limits (30k+ users)**
   - **Problem:** Too many API calls to single Chatwoot instance
   - **Solution:** Implement aggressive caching (Redis), batch requests, consider Chatwoot horizontal scaling
   - **Alternative:** Build direct PostgreSQL integration to Chatwoot's database for read-heavy operations

## Anti-Patterns

### Anti-Pattern 1: Direct Chatwoot API Calls from Frontend

**What people do:** Expose Chatwoot API credentials in frontend code and call Chatwoot directly from client components.

**Why it's wrong:**
- Security risk: API tokens exposed in browser
- CORS issues: Chatwoot may not allow cross-origin requests
- No request transformation: Can't aggregate or enrich data
- Rate limiting: No control over API usage

**Do this instead:** Always proxy through Next.js API routes. Frontend should only call `/api/chatwoot/*`, never Chatwoot directly.

### Anti-Pattern 2: Global Prisma Client Without Tenant Context

**What people do:** Create a single Prisma client and use it everywhere without tenant filtering.

**Why it's wrong:**
- Data leakage: Accidental cross-tenant queries
- Security breach: One query mistake exposes all tenant data
- Hard to debug: No automatic enforcement

**Do this instead:** Use Prisma middleware or client extensions to enforce tenant context on every query. Pass `tenantId` to every DAL function.

```typescript
// ❌ BAD
const contacts = await prisma.contact.findMany()

// ✅ GOOD
const contacts = await prisma.contact.findMany({
  where: { tenantId }
})

// ✅ EVEN BETTER (with middleware)
const client = getTenantPrismaClient(tenantId)
const contacts = await client.contact.findMany() // auto-filtered
```

### Anti-Pattern 3: Storing Chatwoot Tokens in Frontend State

**What people do:** Fetch Chatwoot access token via API and store in React state/localStorage for subsequent requests.

**Why it's wrong:**
- XSS vulnerability: Token accessible to malicious scripts
- Token expiration: Frontend must handle refresh logic
- Session management: Token might outlive user session

**Do this instead:** Keep tokens server-side only. Use httpOnly session cookies. Frontend never sees Chatwoot tokens.

### Anti-Pattern 4: Running WebSocket Server Inside Next.js API Route

**What people do:** Try to create WebSocket server in `app/api/ws/route.ts` with long-running connection.

**Why it's wrong:**
- Serverless incompatible: Functions timeout after 60s (Vercel)
- Scaling issues: Each Next.js instance maintains connections
- Resource waste: Next.js optimized for request/response, not persistent connections

**Do this instead:**
- **Self-hosted:** Use Next.js custom server with WebSocket upgrade
- **Vercel/serverless:** Deploy separate WebSocket service (Node.js + Socket.IO)
- **Alternative:** Use Server-Sent Events (SSE) for one-way real-time updates if full WebSocket not needed

### Anti-Pattern 5: One-to-One Chatwoot Account Per User

**What people do:** Create a separate Chatwoot account for every user instead of one account per tenant.

**Why it's wrong:**
- Chatwoot overhead: Accounts are heavy resources
- Data isolation: Can't share conversations/contacts within tenant
- Cost: Chatwoot pricing often per account
- Complexity: Managing thousands of accounts

**Do this instead:** One Chatwoot account per tenant. Multiple users within the tenant share the account. Use Chatwoot's agent roles for permissions. Store additional user metadata in Prisma.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| **Chatwoot REST API** | BFF Proxy via Next.js API Routes | Use `/api/chatwoot/proxy` route that forwards any endpoint with auth headers injected |
| **Chatwoot ActionCable** | Separate WebSocket Relay Service or Next.js Custom Server | ActionCable library connects to `wss://chatwoot.example.com/cable` with token |
| **PostgreSQL (Prisma)** | Direct connection via Prisma Client with connection pooling | Use PgBouncer in production for connection pooling |
| **Redis (Sessions)** | Session store for next-auth or iron-session | Required when scaling beyond single instance |
| **Stripe (Billing)** | Next.js API route webhook handler + Prisma for subscription data | Map Stripe customer ID to tenant ID |
| **Email (Transactional)** | SendGrid/Postmark via Next.js API or Chatwoot's built-in email | Use Chatwoot for support emails, own service for auth/billing emails |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| **Next.js ↔ Prisma DB** | Prisma Client (direct) | Always pass tenant context, use connection pooling in production |
| **Next.js ↔ Chatwoot API** | HTTP REST (axios/fetch) | Inject auth headers, implement retry logic for 429/500 errors |
| **Next.js ↔ WebSocket Relay** | Socket.IO client or SSE | Frontend establishes connection on dashboard load, passes session token |
| **WebSocket Relay ↔ Chatwoot WS** | ActionCable consumer | One persistent connection per tenant (or use shared connection with channels) |
| **Chatwoot → Next.js Webhooks** | HTTP POST to `/api/webhooks/chatwoot` | Verify webhook signature, process async with queue if heavy |
| **Frontend ↔ Next.js API** | fetch() or React Server Actions | Server Actions for mutations, API routes for external calls |

## Build Order Implications

Based on dependencies between components, recommended build sequence:

### Phase 1: Foundation (Week 1-2)
1. **Prisma schema** for tenants, users, tenant_memberships
2. **Auth system** (session management, login/signup)
3. **Basic Next.js routing** (dashboard layout, tenant context)
4. **Chatwoot API client** (basic wrapper with token injection)

**Rationale:** Auth and tenant context are required for everything else. Can't test multi-tenancy without it.

### Phase 2: Core Integration (Week 3-4)
1. **Chatwoot token mapping** (store tokens in Prisma, refresh logic)
2. **BFF proxy routes** for key endpoints (conversations, messages)
3. **DAL layer** with tenant filtering middleware
4. **Basic inbox UI** consuming Chatwoot API via proxy

**Rationale:** Proves the core architecture works. Can see Chatwoot data in Next.js UI.

### Phase 3: Real-Time (Week 5-6)
1. **WebSocket relay service** (separate Node.js app or Next.js custom server)
2. **ActionCable integration** (connect to Chatwoot WebSocket)
3. **Frontend WebSocket client** (Socket.IO or native WebSocket)
4. **Real-time UI updates** (new messages, typing indicators)

**Rationale:** Real-time is complex but not blocking for MVP. Can launch without it initially.

### Phase 4: CRM & Analytics (Week 7-8)
1. **Prisma schema extensions** for CRM entities (deals, notes, custom fields)
2. **Chatwoot webhooks** to sync contact creation/updates
3. **Analytics schema** (conversations, response times, CSAT)
4. **Dashboard UI** for analytics/CRM

**Rationale:** Differentiator features. Requires stable base to build on.

### Phase 5: White-Label & Polish (Week 9-10)
1. **White-label config** in Prisma (custom domain, branding)
2. **Dynamic theming** based on tenant config
3. **Custom domain routing** (if multi-domain support)
4. **Performance optimization** (caching, code splitting)

**Rationale:** Nice-to-have features. Should have working product before customizing appearance.

## Deployment Architecture

### Recommended Stack for Different Scenarios

**Scenario A: Self-Hosted (VPS/Dedicated Server)**
```
┌─────────────────────────────────────┐
│        Single Server (4GB+ RAM)     │
├─────────────────────────────────────┤
│  Next.js (Custom Server) :3000      │
│  ├── API Routes (BFF)               │
│  ├── WebSocket Server (built-in)    │
│  └── Static assets                  │
├─────────────────────────────────────┤
│  Chatwoot (Docker) :3001            │
│  ├── Rails API                      │
│  ├── ActionCable WS                 │
│  └── Sidekiq (background jobs)      │
├─────────────────────────────────────┤
│  PostgreSQL :5432                   │
│  ├── Chatwoot DB                    │
│  └── Prisma DB (separate database)  │
├─────────────────────────────────────┤
│  Redis :6379                        │
│  ├── Chatwoot (cache)               │
│  └── Next.js (sessions)             │
└─────────────────────────────────────┘
```

**Pros:** Simple, cost-effective ($20-50/mo), full control
**Cons:** Manual scaling, single point of failure, requires DevOps skills

**Scenario B: Hybrid (Next.js Serverless + Self-Hosted Services)**
```
┌─────────────────────────────────────┐
│  Vercel (Next.js)                   │
│  ├── SSR/SSG Pages                  │
│  ├── API Routes (serverless)        │
│  └── Edge Functions                 │
└─────────┬───────────────────────────┘
          │ (calls)
          ▼
┌─────────────────────────────────────┐
│  VPS/Cloud VM                       │
├─────────────────────────────────────┤
│  WebSocket Relay (Node.js) :3001    │
│  ├── Socket.IO Server               │
│  └── ActionCable Client             │
├─────────────────────────────────────┤
│  Chatwoot (Docker) :3002            │
└─────────┬───────────────────────────┘
          │
          ▼
┌─────────────────────────────────────┐
│  Managed PostgreSQL (Supabase/etc)  │
└─────────────────────────────────────┘
```

**Pros:** Next.js scales automatically, WebSocket separate, managed DB
**Cons:** More complex, higher cost, CORS/networking setup

**Scenario C: Full Serverless (AWS/GCP)**
```
Next.js (Lambda/Cloud Run) + Separate WebSocket Service (ECS/Cloud Run)
+ Managed PostgreSQL + Managed Redis + Chatwoot (ECS/GKE)
```

**Pros:** Auto-scaling, high availability, managed infrastructure
**Cons:** Expensive at scale, vendor lock-in, cold start latency

### Docker Compose Example (Scenario A)

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

  chatwoot:
    image: chatwoot/chatwoot:latest
    depends_on:
      - postgres
      - redis
    environment:
      DATABASE_URL: postgresql://postgres:${DB_PASSWORD}@postgres:5432/chatwoot
      REDIS_URL: redis://redis:6379

  next-app:
    build:
      context: ./chatwize
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - chatwoot
    environment:
      DATABASE_URL: postgresql://postgres:${DB_PASSWORD}@postgres:5432/chatwize
      CHATWOOT_API_URL: http://chatwoot:3000
      CHATWOOT_WS_URL: ws://chatwoot:3000/cable

volumes:
  postgres_data:
```

## Sources

**Next.js & BFF Pattern:**
- [Building APIs with Next.js](https://nextjs.org/blog/building-apis-with-nextjs)
- [Next.js Proxy Documentation](https://nextjs.org/docs/app/api-reference/file-conventions/proxy)
- [Setting Up Proxy API Routes in Next.js](https://blog.nextsaaspilot.com/nextjs-proxy-api-route/)
- [Backend for Frontend Pattern Guide](https://nextjs.org/docs/app/guides/backend-for-frontend)
- [Building Secure BFF with Next.js](https://vishal-vishal-gupta48.medium.com/building-a-secure-scalable-bff-backend-for-frontend-architecture-with-next-js-api-routes-cbc8c101bff0)

**Multi-Tenant Architecture:**
- [Multi-tenant with Next.js and Prisma](https://www.mikealche.com/software-development/how-to-create-a-multi-tenant-application-with-next-js-and-prisma)
- [Next.js for SaaS Best Practices](https://www.ksolves.com/blog/next-js/best-practices-for-saas-dashboards)
- [Multi-tenancy Best Practices Discussion](https://github.com/vercel/next.js/discussions/20841)

**Authentication & Session Management:**
- [Next.js Authentication Guide](https://nextjs.org/docs/app/guides/authentication)
- [NextAuth with External API](https://medium.com/@muhebollah.diu/building-a-complete-authentication-system-with-nextauth-js-v4-and-external-api-in-next-js-15-3544c3dc561c)
- [Authentication with External Backend](https://medium.com/@urboifox/authentication-in-next-ajs-with-an-external-backend-262fc2748158)

**WebSocket & Real-Time:**
- [How to Handle WebSocket in Next.js](https://oneuptime.com/blog/post/2026-01-24-nextjs-websocket-handling/view)
- [Rails ActionCable with Next.js](https://tomkral.hashnode.dev/how-to-make-rails-action-cable-work-in-your-nextjs-app)
- [Next.js Real-Time Chat Guide](https://eastondev.com/blog/en/posts/dev/20260107-nextjs-realtime-chat/)
- [WebSocket Deployment with Docker](https://fly.io/javascript-journal/websockets-with-nextjs/)

**Data Layer & Prisma:**
- [Data Access Layer in Next.js](https://medium.com/@javadmohammadi.career/in-a-next-js-cb8e180bf10a)
- [Prisma Connection Pooling Documentation](https://www.prisma.io/docs/orm/prisma-client/setup-and-configuration/databases-connections/connection-pool)
- [API Layer Integration Guide](https://www.iflair.com/api-layer-integration-with-next-js-endpoints-a-guide-for-next-js-developers/)

---
*Architecture research for: ChatWize Multi-tenant SaaS*
*Researched: 2026-02-11*
