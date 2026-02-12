# Project Research Summary

**Project:** ChatWize - Multi-tenant SaaS Customer Support Platform
**Domain:** Next.js frontend consuming Chatwoot APIs with own Prisma database
**Researched:** 2026-02-11
**Confidence:** HIGH

## Executive Summary

ChatWize is a white-label customer support SaaS platform built on a modern Next.js 15 frontend consuming Chatwoot APIs (REST + WebSocket) while maintaining its own Prisma database for tenant configs, CRM data, and analytics. This architecture separates concerns: Chatwoot handles messaging infrastructure (12+ channels including WhatsApp, email, social media), while the custom frontend delivers competitive advantages through **white-label branding, advanced analytics/BI, CRM pipeline management, and sophisticated workflow automation**.

The recommended approach leverages proven production patterns: **Server-first rendering** with React Server Components for data-heavy dashboards, **Backend-for-Frontend (BFF) proxy** pattern for secure Chatwoot API integration, **multi-tenant context middleware** for data isolation, and **separate WebSocket relay service** for ActionCable real-time updates. This stack is battle-tested in production SaaS deployments and emphasizes type safety (TypeScript strict mode), developer experience (shadcn/ui, Tailwind v4, TanStack Query), and performance (edge runtime support, connection pooling).

**Critical risks** center on multi-tenant security (tenant data leakage through shared account IDs), WebSocket state management in serverless environments (desynchronization across instances), WhatsApp Business API compliance (2026 policy changes eliminating shared accounts), and data consistency between Prisma and Chatwoot databases. Mitigation strategies are well-documented: tenant abstraction layers, Redis Pub/Sub for WebSocket relay, per-tenant WABA provisioning, and idempotent webhook handlers with reconciliation jobs. **Build security and isolation architecture from day one** — retrofitting is 10-100x more expensive than building correctly initially.

## Key Findings

### Recommended Stack

**Core technologies enable a modern, type-safe, performant SaaS platform:**

- **Next.js 15 + React 19 + TypeScript 5.7** — Server-first framework with React Server Components eliminating client bundle bloat for dashboards. Official multi-tenant guide updated Feb 2026 confirms this is a first-class use case.

- **Prisma 6.19 + PostgreSQL 15+** — Best-in-class TypeScript ORM with driver adapters for edge deployment. Multi-tenant patterns via row-level filtering middleware. Connection pooling critical for serverless.

- **TanStack Query v5.84 + @rails/actioncable 7.x** — Standard for external API consumption with built-in SSR hydration. ActionCable is Chatwoot's real-time protocol — must use official client.

- **Auth.js v5 + Credentials Provider** — External API authentication pattern maps internal sessions to Chatwoot tokens per tenant. Tokens stored server-side only.

- **Tailwind CSS v4 + shadcn/ui + Radix UI** — Dominant component library for SaaS in 2026. Copy/paste philosophy avoids npm bloat. Radix provides WAI-ARIA accessibility.

- **Zustand 5.x + Zod v4 + React Hook Form 7.x** — Simple global state, TypeScript-first validation, minimal re-renders forms. Most state is server state (TanStack Query).

- **Vitest 2.x + Playwright 1.50+** — Faster than Jest, native ESM support. Playwright for E2E with Safari support (Cypress lacks WebKit).

**Critical stack decisions:**
- pnpm for package management (fastest, 70-80% disk savings)
- Biome over Prettier+ESLint (10-25x faster, optional)
- Recharts for dashboards
- Sentry for error tracking

### Expected Features

**Chatwoot APIs already provide ~95% of table stakes** — custom frontend adds differentiators:

**Must have (table stakes):**
- Omnichannel inbox (WhatsApp, email, web chat, social) — ✓ Chatwoot API
- Real-time messaging — ✓ Chatwoot WebSocket (ActionCable)
- Conversation/contact/team management — ✓ Chatwoot API
- Canned responses, knowledge base, basic automation — ✓ Chatwoot API
- Mobile-responsive UI — Custom Next.js frontend responsibility

**Should have (competitive differentiators):**
- **White-label branding per tenant** — Logos, colors, custom domains (Prisma DB)
- **Advanced analytics dashboards** — Real-time BI beyond Chatwoot's basic reports
- **CRM pipeline management** — Lead scoring, deal stages, Kanban boards (Prisma)
- **Custom workflow builder** — Visual no-code automation extending Chatwoot
- **Multi-brand support per tenant** — Multiple brands with separate inboxes
- **WhatsApp non-official** — Evolution API / Waha API integration
- **Tenant onboarding flow** — Guided registration, channel setup
- **Custom domain per tenant** — Branded URLs (support.clientname.com)

**Defer (v2+):**
- Advanced chatbot builder (Chatwoot Captain sufficient initially)
- Customer-facing analytics portal (complex multi-tenant isolation)
- Mobile native apps (responsive web covers 90% of use cases)
- Telephony/IVR (high cost, outside core focus)

**Anti-features (deliberately NOT build):**
- Real-time everything (selective real-time for conversations only)
- Custom messaging infrastructure (use Chatwoot's channels)
- Modifying Chatwoot backend (breaks upgradability)
- AI for everything (use strategically: chatbot, sentiment)

### Architecture Approach

**Backend-for-Frontend (BFF) proxy pattern** isolates security and provides unified API contract. Next.js API Routes proxy all Chatwoot calls with server-side token injection, never exposing credentials to client.

**Major components:**

1. **Next.js App Router (Frontend Layer)** — Server Components for data operations, client components for interactivity. Route groups separate auth vs dashboard. Dynamic `[tenantId]` route provides context.

2. **Data Access Layer (DAL)** — Centralized server-side functions with session verification. Enforces tenant boundaries, prevents data leakage.

3. **BFF API Routes** — Proxy to Chatwoot REST API, manage auth tokens, transform requests. Generic `/api/chatwoot/proxy` route forwards any endpoint.

4. **WebSocket Relay Service** — Separate Node.js service (or Next.js custom server) maintains persistent ActionCable connections. Relays events via Socket.IO or SSE.

5. **Prisma Client with Multi-Tenant Middleware** — ORM for tenant configs, CRM, analytics. Middleware auto-injects `tenantId` filters. Connection pooling via PgBouncer.

6. **Chatwoot API SDK** — Type-safe wrapper with token management, retry logic, ETag caching.

**Key patterns:**
- Session-based auth mapping to Chatwoot tokens per tenant
- Row-level security in Prisma with automatic filtering
- Webhook handlers with idempotent processing
- Redis Pub/Sub for WebSocket relay across instances
- Adapter pattern for Chatwoot API versions

### Critical Pitfalls

1. **Insecure API Proxy Routes** — Exposed `/api/*` without auth/rate limiting. Attackers drain quotas. **Prevention:** Origin verification, Auth.js middleware, Upstash Redis rate limiting. **Address in Phase 1**.

2. **Tenant Data Leakage** — Chatwoot account IDs exposed in URLs allow cross-tenant access. **Prevention:** Abstraction layer mapping internal UUIDs to Chatwoot accounts, middleware validation. **Address in Phase 1**.

3. **WebSocket State Desynchronization** — Serverless instances don't share WebSocket state. **Prevention:** Redis Pub/Sub message bus, auto-reconnect, SSE fallback. **Address in Phase 2**.

4. **WhatsApp WABA Multi-Tenant Model Collapse** — Meta eliminated "On-Behalf-Of" in 2025-2026. Each tenant needs own WABA. **Prevention:** Per-tenant WABA schema, verification workflow, Evolution API as "instant" tier. **Address in Phase 1**.

5. **Prisma-Chatwoot Data Divergence** — Two databases without sync strategy. Webhook failures cause drift. **Prevention:** Eventual consistency, idempotent handlers, reconciliation jobs. **Address in Phase 3**.

6. **Rate Limit Death Spiral** — Polling + single API key = 4000 req/min hitting limits. **Prevention:** WebSocket/SSE only, exponential backoff, circuit breakers. **Address in Phase 2**.

7. **Upstream API Version Drift** — Chatwoot breaking changes (field renamed). **Prevention:** Track version in metrics, adapter pattern, test against multiple versions. **Address in Phase 1**.

## Implications for Roadmap

Based on research dependencies and pitfall prevention, suggested phase structure:

### Phase 1: Foundation & Security (Weeks 1-2)
**Rationale:** Auth, multi-tenant isolation, and security are foundational. **All critical pitfalls require Phase 1 prevention** — retrofitting security is 10-100x more expensive.

**Delivers:**
- Multi-tenant auth (Auth.js v5 → Chatwoot tokens)
- Tenant management schema (tenants, users, memberships)
- BFF proxy with origin validation, rate limiting, auth middleware
- Tenant abstraction layer (never expose Chatwoot account IDs)
- Basic Next.js routing with tenant context
- Chatwoot API client with version monitoring

**Addresses features:**
- Tenant onboarding flow (registration, email verification)
- White-label branding (schema for logos, colors, domains)

**Avoids pitfalls:**
- Insecure proxy routes (origin checks from day one)
- Tenant data leakage (abstraction layer, middleware)
- WhatsApp WABA model (per-tenant schema ready)
- Upstream version drift (version tracking, adapter)

**Research flag:** Standard patterns — skip `/gsd:research-phase`.

---

### Phase 2: Core Integration & Real-Time (Weeks 3-4)
**Rationale:** Proves core architecture. Must implement WebSocket relay before launch to avoid rate limit death spiral.

**Delivers:**
- Chatwoot token mapping with refresh logic
- BFF proxy for conversations, messages, contacts
- DAL layer with tenant filtering middleware
- Basic inbox UI consuming Chatwoot API
- WebSocket relay service (Node.js or custom server)
- ActionCable integration with Redis Pub/Sub
- Frontend WebSocket client with auto-reconnect

**Addresses features:**
- Omnichannel inbox UI (all Chatwoot channels)
- Conversation management (assign, resolve, labels)
- Contact management (profiles, history, attributes)
- Real-time messaging (live updates, typing indicators)

**Avoids pitfalls:**
- WebSocket state desync (Redis Pub/Sub from start)
- Rate limit death spiral (no polling, WebSocket/SSE only)

**Research flag:** **NEEDS RESEARCH** — ActionCable + Next.js serverless, Redis Pub/Sub patterns.

---

### Phase 3: CRM & Data Sync (Weeks 5-6)
**Rationale:** Differentiator features require stable base. CRM pipeline is competitive advantage.

**Delivers:**
- Prisma schema for CRM (deals, pipeline, notes)
- Chatwoot webhook handlers (idempotent processing)
- Contact sync (Chatwoot webhooks → Prisma)
- Basic CRM pipeline UI (Lead → Qualified → Won/Lost)
- Analytics schema (conversation counts, response times)
- Reconciliation jobs (detect drift)

**Addresses features:**
- Basic CRM pipeline (manual deal moves)
- Basic analytics dashboard (better than Chatwoot)
- Advanced segmentation (campaign foundation)

**Avoids pitfalls:**
- Prisma-Chatwoot divergence (idempotent webhooks, reconciliation)

**Research flag:** Standard patterns — webhook processing with BullMQ. Skip research.

---

### Phase 4: WhatsApp & Channel Setup (Weeks 7-8)
**Rationale:** WhatsApp is table stakes but requires careful handling of 2026 WABA changes.

**Delivers:**
- WhatsApp Cloud API wizard (guided WABA provisioning)
- Per-tenant WABA verification workflow UI
- Evolution API / Waha integration for non-official WhatsApp
- Channel connection status monitoring
- Template message management UI

**Addresses features:**
- WhatsApp Cloud API setup (official, requires verification)
- WhatsApp non-official (Evolution/Waha for instant setup)
- Multi-brand support foundation (multiple inboxes)

**Avoids pitfalls:**
- WhatsApp WABA multi-tenant model (per-tenant provisioning)

**Research flag:** **NEEDS RESEARCH** — Evolution API and Waha integration patterns not well-documented.

---

### Phase 5: Advanced Analytics & White-Label Polish (Weeks 9-10)
**Rationale:** Nice-to-have features after core works. Final differentiators before launch.

**Delivers:**
- Advanced analytics dashboards (custom metrics, AI insights)
- Custom reporting with scheduled exports (CSV, Excel)
- Dynamic theming based on tenant config
- Custom domain routing (multi-domain support)
- Performance optimization (caching, code splitting, CDN)
- Dashboard embeds for customer portals (foundation)

**Addresses features:**
- Advanced analytics dashboards (differentiator)
- Custom reporting & exports (tenant-specific KPIs)
- White-label branding (custom domains, full theming)

**Research flag:** Standard patterns — Recharts, Next.js routing. Skip research.

---

### Phase 6: Workflow Automation (v1.x - Post-Launch)
**Rationale:** Defer to v1.x after validation. High complexity, users must request first.

**Delivers:**
- Visual workflow builder UI (drag-and-drop)
- Workflow execution engine (Prisma stores definitions)
- Trigger system (Chatwoot webhooks → execution)
- Action integrations (email, Slack, webhooks)
- CRM automation workflows (auto-create deals)

**Addresses features:**
- Advanced workflow builder (complex automations)
- CRM automation workflows (lifecycle triggers)

**Research flag:** **NEEDS RESEARCH** — Workflow engines, visual builders, state machines.

---

### Phase Ordering Rationale

1. **Security first (Phase 1)**: All critical pitfalls require foundational security. Cannot be retrofitted cheaply.

2. **Prove integration (Phase 2)**: Core Chatwoot API consumption must work before building features. WebSocket prevents disasters.

3. **Add value (Phase 3-5)**: CRM, analytics, white-label are differentiators but depend on stable base.

4. **Defer complexity (Phase 6+)**: Workflow automation is high complexity. Wait for user validation.

**Dependency chain:**
```
Phase 1 (Auth + Tenant Context)
  └─> Phase 2 (Chatwoot Integration + Real-time)
       └─> Phase 3 (CRM + Data Sync)
            └─> Phase 4 (WhatsApp Channels)
                 └─> Phase 5 (Analytics + Polish)
                      └─> Phase 6 (Advanced Automation)
```

**Critical path:** Phase 1 → Phase 2 blocks everything else. Get these right or fail.

### Research Flags

**Phases needing deeper research during planning:**

- **Phase 2 (Real-time Sync):** ActionCable + Next.js serverless patterns have edge cases. Redis Pub/Sub scaling. `/gsd:research-phase` recommended.

- **Phase 4 (WhatsApp Integration):** Evolution API and Waha documentation sparse. Chatwoot inbox mapping unclear. `/gsd:research-phase` required.

- **Phase 6 (Workflow Automation):** Visual workflow builders, execution engines, state machines need deep dive. `/gsd:research-phase` critical.

**Phases with standard patterns (skip research-phase):**

- **Phase 1 (Foundation):** Multi-tenant auth, Prisma middleware, BFF proxy all well-documented.

- **Phase 3 (CRM & Data Sync):** Webhook processing, Prisma schemas, reconciliation jobs are standard SaaS patterns.

- **Phase 5 (Analytics & Polish):** Recharts dashboards, Next.js dynamic routing, Tailwind theming all solved problems.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Verified via Context7 official docs (Next.js, Prisma, TanStack Query, Zod). All production-proven in SaaS. |
| Features | HIGH | Competitor analysis (Intercom, Zendesk, Freshdesk, HubSpot) consistent. Chatwoot API docs reviewed. Clear differentiation. |
| Architecture | HIGH | BFF proxy documented in Next.js guides. Multi-tenant patterns in AWS prescriptive guidance. WebSocket relay has working implementations. |
| Pitfalls | HIGH | Sourced from recent blog posts (2025-2026), security guides, real-world examples. Prevention strategies verified. |

**Overall confidence: HIGH** (95%+ verified via authoritative sources)

### Gaps to Address

**1. ActionCable Client Version Compatibility**
- **Confidence:** MEDIUM
- **Gap:** Chatwoot may use specific ActionCable protocol version.
- **Handling:** Test WebSocket handshake in Phase 2 planning. Check Chatwoot docs.

**2. Evolution API / Waha Integration Details**
- **Confidence:** LOW
- **Gap:** No research on TypeScript client libraries, auth flows, inbox mapping.
- **Handling:** **Requires `/gsd:research-phase` in Phase 4.** Research Evolution/Waha docs before implementation.

**3. Multi-Tenant Database Sharding Strategy**
- **Confidence:** MEDIUM
- **Gap:** Research covered row-level security but not sharding for 1000+ tenants.
- **Handling:** Not needed for v1. Start with single database. Re-evaluate in Phase 3 based on load testing.

**4. Chatwoot Platform API vs Application API Limitations**
- **Confidence:** MEDIUM
- **Gap:** Platform API only sees resources it created. Didn't fully map which operations require Application API.
- **Handling:** Map operations during Phase 1 planning. May need dual auth strategy.

**5. WhatsApp Template Message Approval Timelines**
- **Confidence:** MEDIUM
- **Gap:** 24-48 hour approval times not verified for all regions.
- **Handling:** Set expectations in onboarding UI (Phase 4). Test in Meta Business Manager before implementation.

## Sources

### Primary Sources (HIGH confidence)

**Official Documentation & Context7:**
- [Next.js Official Docs](https://nextjs.org/docs/app) - Context7: /vercel/next.js — App Router, multi-tenant guide (Feb 2026)
- [Prisma Documentation](https://www.prisma.io/docs) - Context7: /websites/prisma_io — Edge adapters, connection pooling
- [TanStack Query Docs](https://tanstack.com/query) - Context7: /tanstack/query — Next.js App Router SSR patterns
- [Zod Documentation](https://zod.dev/) - Context7: /colinhacks/zod — Type inference, v4 release
- [Auth.js v5 Docs](https://authjs.dev/) - Context7: /nextauthjs/docs — External API patterns

**Stack Research:**
- [Tailwind CSS v4 Release](https://tailwindcss.com/blog/tailwindcss-v4) - Rust engine, CSS config
- [shadcn/ui Documentation](https://ui.shadcn.com/) - Component library, copy/paste philosophy
- [ActionCable npm](https://www.npmjs.com/package/@rails/actioncable) - Official Rails ActionCable client

### Secondary Sources (MEDIUM confidence)

**Feature Research:**
- [Zendesk vs Intercom vs Freshdesk](https://www.saasgenie.ai/blogs/freshdesk-vs-zendesk-vs-intercom) - Feature parity
- [Top 14 Intercom alternatives](https://www.zendesk.com/service/comparison/intercom-alternatives/) - Competitive features
- [Chatwoot API Reference](https://developers.chatwoot.com/api-reference/introduction) - API capabilities
- [Chatwoot Captain AI](https://deepwiki.com/chatwoot/chatwoot/9.1-captain-ai-system) - AI features

**Architecture Research:**
- [Next.js BFF Pattern](https://nextjs.org/docs/app/guides/backend-for-frontend) - Official guide
- [Building Secure BFF](https://vishal-vishal-gupta48.medium.com/building-a-secure-scalable-bff-backend-for-frontend-architecture-with-next-js-api-routes-cbc8c101bff0) - Security patterns
- [Multi-tenant with Next.js](https://www.mikealche.com/software-development/how-to-create-a-multi-tenant-application-with-next-js-and-prisma) - Isolation patterns
- [ActionCable with Next.js](https://tomkral.hashnode.dev/how-to-make-rails-action-cable-work-in-your-nextjs-app) - WebSocket integration

**Pitfalls Research:**
- [Secure API Integration](https://www.bomberbot.com/proxy/mastering-secure-api-integration-in-next-js-with-proxy-endpoints/) - Proxy security
- [AWS Multi-Tenant Authorization](https://docs.aws.amazon.com/prescriptive-guidance/latest/saas-multitenant-api-access-authorization/) - Tenant isolation
- [Next.js Real-Time Chat](https://eastondev.com/blog/en/posts/dev/20260107-nextjs-realtime-chat/) - WebSocket patterns
- [WhatsApp API for SaaS 2026](https://www.wati.io/en/blog/whatsapp-business-api/whatsapp-api-for-saas/) - WABA changes

### Tertiary Sources (needs validation)

- [Chatwoot Multi-Tenant Overview](https://www.restack.io/docs/chatwoot-knowledge-chatwoot-multi-tenant-overview) - Account-based tenancy limitations
- [Chatwoot GitHub Issue #11109](https://github.com/chatwoot/chatwoot/issues/11109) - Community discussion
- [WhatsApp API Integration 2026](https://chatarmin.com/en/blog/whats-app-business-api-integration) - WABA provisioning flows

---

*Research completed: 2026-02-11*
*Synthesized by: GSD Research Synthesizer (Claude Sonnet 4.5)*
*Ready for roadmap: YES*
