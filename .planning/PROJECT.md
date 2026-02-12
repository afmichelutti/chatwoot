# ChatWize

## What This Is

ChatWize is a multi-tenant SaaS customer support platform with a fully custom Next.js frontend, powered by Chatwoot's APIs as the backend engine. It offers complete design/UX control, white-label branding per tenant, and advanced features (CRM, dashboards, automations) beyond what Chatwoot provides natively. Each tenant maps to a Chatwoot account within a single shared instance.

## Core Value

Businesses can manage all customer conversations across every channel (WhatsApp, email, web chat, social media) through a modern, branded interface — with CRM, analytics and automation capabilities that go beyond basic support.

## Requirements

### Validated

<!-- Capabilities available via Chatwoot APIs (backend engine) -->

- ✓ Multi-tenant account management — Chatwoot API
- ✓ Omnichannel messaging (WhatsApp, Facebook, Instagram, Twitter, Telegram, LINE, Email, SMS, Web Widget) — Chatwoot API
- ✓ Conversation management (assign, resolve, reopen, labels, teams) — Chatwoot API
- ✓ Contact management (profiles, merge, search, filter) — Chatwoot API
- ✓ Team and agent management — Chatwoot API
- ✓ Canned responses — Chatwoot API
- ✓ Automation rules — Chatwoot API
- ✓ Webhooks and integrations — Chatwoot API
- ✓ Reports and analytics (basic) — Chatwoot API
- ✓ Real-time updates via WebSocket — Chatwoot ActionCable
- ✓ WhatsApp Cloud API integration — Chatwoot API
- ✓ Role-based access control (admin, agent) — Chatwoot API

### Active

<!-- New capabilities ChatWize needs to build -->

- [ ] Custom Next.js frontend consuming Chatwoot APIs
- [ ] Onboarding flow: registration, email verification, WhatsApp connection
- [ ] White-label branding per tenant (logo, colors, domain)
- [ ] WhatsApp non-official integration (Evolution API / Waha API)
- [ ] CRM advanced: sales pipeline, lead scoring, CRM automations
- [ ] Custom dashboards and BI (metrics, reports, analytics beyond Chatwoot)
- [ ] Advanced automation workflows (chatbots, custom flows)
- [ ] Prisma database for tenant configs, analytics data, and extra features
- [ ] Multi-tenant auth layer (Next.js ↔ Chatwoot account mapping)
- [ ] All Chatwoot channels exposed via custom UI

### Out of Scope

- Modifying Chatwoot backend source code — we consume APIs only
- Mobile native app — web-first, mobile later
- Building own messaging infrastructure — Chatwoot handles message routing
- Own email/SMS delivery — Chatwoot manages channel connections

## Context

**Chatwoot as Backend Engine:**
- Chatwoot v4.7.0-custom running as single shared instance
- REST API v1/v2 available at `app/controllers/api/`
- WebSocket via ActionCable for real-time updates
- API docs available in `docs/json/`
- Each tenant = one Chatwoot Account (multi-tenant built-in)

**WhatsApp Strategy:**
- Official: Via Chatwoot's WhatsApp Cloud API integration
- Non-official: Via Evolution API or Waha API (additional integration needed)

**Tech Stack (New Frontend):**
- Next.js (React) — SSR/SSG, App Router
- Prisma — ORM for ChatWize's own database (configs, analytics, CRM data)
- Chatwoot APIs — all business logic and messaging

**Existing Chatwoot Capabilities (reference):**
- 12+ messaging channels supported
- Agent/team/account management
- Automation rules engine
- Contact management with custom attributes
- Reports (conversation, agent, team metrics)
- Webhook system for external integrations

## Constraints

- **Backend**: Chatwoot APIs only — no direct database access to Chatwoot's PostgreSQL
- **Architecture**: Single Chatwoot instance shared across all tenants
- **WhatsApp**: Must support both official (Cloud API) and non-official (Evolution/Waha)
- **Real-time**: Must consume Chatwoot WebSocket for live updates
- **Auth**: Need own auth layer (Next.js) that maps to Chatwoot user/account tokens

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Next.js for frontend | Full control over UX, SSR for performance, React ecosystem | — Pending |
| Prisma for extra data | Need own DB for configs, analytics, CRM beyond Chatwoot | — Pending |
| Single Chatwoot instance | Simpler ops, multi-tenant via accounts already built-in | — Pending |
| Evolution/Waha for non-official WhatsApp | Complement official Cloud API with non-official access | — Pending |
| All channels in v1 | Leverage all Chatwoot channel APIs from day one | — Pending |

---
*Last updated: 2026-02-11 after initialization*
