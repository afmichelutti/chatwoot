# ChatWize

## What This Is

ChatWize is a multi-tenant SaaS customer support platform built from scratch with Next.js (fullstack) and Prisma/PostgreSQL. It provides WhatsApp-focused customer communication (official Cloud API + non-official via Evolution API and Waha), with white-label branding per tenant, agent/team management, conversation routing, permissions, and analytics dashboards. Inspired by Chatwoot's feature set but with own backend — simpler architecture, no external API dependency.

## Core Value

Businesses can manage WhatsApp conversations through a modern, branded interface with team collaboration, smart routing, and actionable analytics — all under their own brand.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Full-stack Next.js application with own Prisma/PostgreSQL backend
- [ ] Multi-tenant architecture with complete data isolation
- [ ] Auth system: registration, email verification, login/logout, password reset
- [ ] WhatsApp integration: Cloud API (official) + Evolution API + Waha API
- [ ] Conversation inbox with real-time messaging (WebSocket)
- [ ] Agent and team management with roles and permissions
- [ ] Conversation routing and transfer between agents/teams
- [ ] Permission-based conversation visibility (who can see what)
- [ ] Contact management (profiles, history, custom fields)
- [ ] White-label branding per tenant (logo, colors, domain)
- [ ] Analytics dashboards with export (CSV/Excel)
- [ ] Guided onboarding: signup → verify email → connect WhatsApp → create team
- [ ] Automation rules (auto-assignment, business hours)
- [ ] Responsive UI (desktop, tablet, mobile)

### Out of Scope

- Chatwoot dependency — fully independent backend, no API proxy
- Channels beyond WhatsApp in v1 — email, social media, web chat deferred to v2
- CRM pipeline / lead scoring — deferred to v1.x
- Advanced workflow builder — deferred to v1.x
- Mobile native apps — responsive web first
- AI chatbots — deferred to v1.x
- Telephony / IVR — not in roadmap

## Context

**Architecture Decision (2026-02-11):**
Originally planned to use Chatwoot APIs as backend engine. After analysis of pitfalls (auth delegation, WebSocket relay complexity, data sync issues, rate limits, upstream dependency risk), decided to build own backend. The scope is focused (WhatsApp only in v1), and the team has WhatsApp integration experience (Evolution/Waha).

**Chatwoot Codebase (reference only):**
The Chatwoot codebase at `D:\ivox\chatwoot` serves as reference for feature design and data modeling patterns. Codebase map available at `.planning/codebase/`. We are NOT consuming Chatwoot APIs or modifying its code.

**WhatsApp Strategy:**
- Official: Meta WhatsApp Cloud API (direct integration)
- Non-official: Evolution API + Waha API (direct integration)
- All three providers supported from v1

**Tech Stack:**
- Next.js 15 (App Router) — fullstack framework
- React 19 — UI layer
- Prisma 6 + PostgreSQL — database ORM and persistence
- TypeScript (strict) — end-to-end type safety
- TanStack Query v5 — server state management
- Socket.io — real-time WebSocket
- shadcn/ui + Tailwind v4 — design system
- Auth.js v5 — authentication
- Zod — validation

## Constraints

- **Channel v1**: WhatsApp only (Cloud API + Evolution + Waha)
- **Backend**: Own Prisma/PostgreSQL — no external API dependencies
- **Multi-tenant**: Data isolation enforced at Prisma middleware level
- **Real-time**: Socket.io for live conversation updates
- **i18n**: Portuguese (pt-BR) primary, i18n infrastructure for future languages
- **WhatsApp compliance**: Must handle Meta's 2026 WABA policies for official API

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Own backend instead of Chatwoot APIs | Simpler architecture, no proxy/relay complexity, full control, no upstream dependency | — Pending |
| Next.js fullstack | Single framework for frontend + API routes + server actions | — Pending |
| Prisma + PostgreSQL | Type-safe ORM, multi-tenant middleware, direct queries | — Pending |
| WhatsApp only in v1 | Focused scope, team has experience, fastest path to market | — Pending |
| Socket.io for real-time | Direct WebSocket, no ActionCable relay needed | — Pending |
| Three WhatsApp providers | Cloud API (official) + Evolution + Waha covers all use cases | — Pending |

---
*Last updated: 2026-02-11 after architecture pivot (own backend)*
