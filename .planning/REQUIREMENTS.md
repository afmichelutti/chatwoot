# Requirements: ChatWize

**Defined:** 2026-02-11
**Core Value:** Businesses can manage WhatsApp conversations through a modern, branded interface with team collaboration, smart routing, and actionable analytics.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Authentication & Onboarding

- [ ] **AUTH-01**: User can create account with email and password
- [ ] **AUTH-02**: User receives email verification after signup
- [ ] **AUTH-03**: User can log in and stay logged in across browser sessions
- [ ] **AUTH-04**: User can log out from any page
- [ ] **AUTH-05**: User can reset password via email link
- [ ] **AUTH-06**: Multi-tenant isolation enforced — user cannot access another tenant's data
- [ ] **ONBR-01**: New tenant goes through guided onboarding after first login
- [ ] **ONBR-02**: Onboarding includes connecting WhatsApp (choice of provider)
- [ ] **ONBR-03**: Onboarding includes creating first team and inviting agents
- [ ] **ONBR-04**: Tenant workspace is created with initial config in database

### WhatsApp Integration

- [ ] **WHTS-01**: Admin can connect WhatsApp via Meta Cloud API (official)
- [ ] **WHTS-02**: Admin can connect WhatsApp via Evolution API (non-official)
- [ ] **WHTS-03**: Admin can connect WhatsApp via Waha API (non-official)
- [ ] **WHTS-04**: System receives incoming WhatsApp messages via webhook
- [ ] **WHTS-05**: Agent can send outbound WhatsApp messages
- [ ] **WHTS-06**: System handles message status updates (sent, delivered, read)
- [ ] **WHTS-07**: System handles media messages (images, documents, audio, video)
- [ ] **WHTS-08**: Admin can view WhatsApp connection status (connected/disconnected)
- [ ] **WHTS-09**: System reconnects automatically on provider disconnection

### Inbox & Messaging

- [ ] **INBX-01**: Agent can view unified inbox with all conversations
- [ ] **INBX-02**: Agent can send and receive messages in real-time (WebSocket)
- [ ] **INBX-03**: Agent can assign conversation to self, another agent, or team
- [ ] **INBX-04**: Agent can resolve, reopen, and snooze conversations
- [ ] **INBX-05**: Agent can add labels and priority to conversations
- [ ] **INBX-06**: Agent can add internal notes visible only to team
- [ ] **INBX-07**: Agent can use @mentions to notify other agents
- [ ] **INBX-08**: Agent can use canned responses for quick replies
- [ ] **INBX-09**: Agent can send and receive file attachments
- [ ] **INBX-10**: Agent can search conversations by keyword, contact, or status
- [ ] **INBX-11**: Agent can filter conversations by team, agent, status, label
- [ ] **INBX-12**: Conversations update in real-time without page refresh

### Contact Management

- [ ] **CONT-01**: Agent can view contact profile with conversation history
- [ ] **CONT-02**: Agent can edit contact attributes (name, email, phone, custom fields)
- [ ] **CONT-03**: Agent can search and filter contacts
- [ ] **CONT-04**: Agent can merge duplicate contacts
- [ ] **CONT-05**: Contacts are auto-created from incoming WhatsApp messages

### Team & Agent Management

- [ ] **TEAM-01**: Admin can create and manage teams
- [ ] **TEAM-02**: Admin can invite agents by email
- [ ] **TEAM-03**: Admin can assign roles (admin, supervisor, agent)
- [ ] **TEAM-04**: Admin can configure auto-assignment rules per team
- [ ] **TEAM-05**: Admin can deactivate agents
- [ ] **TEAM-06**: Agent can transfer conversation to another team
- [ ] **TEAM-07**: Agent can transfer conversation to specific agent

### Permissions & Visibility

- [ ] **PERM-01**: Admin has full access to all conversations and settings
- [ ] **PERM-02**: Supervisor can view all conversations in their teams
- [ ] **PERM-03**: Agent can only view conversations assigned to them or their team
- [ ] **PERM-04**: Permission rules are enforced at API level (not just UI)
- [ ] **PERM-05**: Admin can configure which teams/inboxes each agent can access

### White Label

- [ ] **WHTL-01**: Admin can set custom logo for their tenant
- [ ] **WHTL-02**: Admin can set custom color theme (primary, secondary, accent)
- [ ] **WHTL-03**: Admin can set custom favicon
- [ ] **WHTL-04**: Tenant branding stored in database and applied across all UI
- [ ] **WHTL-05**: Admin can configure custom domain for their tenant

### Analytics & Reports

- [ ] **ANLR-01**: Admin can view dashboard with conversation volume over time
- [ ] **ANLR-02**: Admin can view average response time and resolution time
- [ ] **ANLR-03**: Admin can view agent performance metrics
- [ ] **ANLR-04**: Admin can view team performance metrics
- [ ] **ANLR-05**: Admin can filter analytics by date range, team, agent
- [ ] **ANLR-06**: Admin can export reports to CSV
- [ ] **ANLR-07**: Admin can export reports to Excel
- [ ] **ANLR-08**: Dashboards display with modern charts

### Automation

- [ ] **AUTO-01**: Admin can create auto-assignment rules (round-robin, load-based)
- [ ] **AUTO-02**: Admin can configure business hours per inbox
- [ ] **AUTO-03**: Admin can set up auto-reply messages (outside business hours)
- [ ] **AUTO-04**: Admin can create basic automation rules (if condition → then action)

### UI/UX

- [ ] **UIUX-01**: Frontend is fully responsive (desktop, tablet, mobile)
- [ ] **UIUX-02**: UI uses modern design system (shadcn/ui + Tailwind)
- [ ] **UIUX-03**: Dark mode support
- [ ] **UIUX-04**: All pages load under 3 seconds on standard connections
- [ ] **UIUX-05**: UI in Portuguese (pt-BR) with i18n infrastructure for future languages

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Additional Channels

- **CHAN-01**: Email channel (IMAP/SMTP)
- **CHAN-02**: Web widget (live chat embeddable)
- **CHAN-03**: Facebook Messenger
- **CHAN-04**: Instagram DM
- **CHAN-05**: Telegram

### CRM

- **CRM-01**: Sales pipeline with customizable deal stages
- **CRM-02**: Lead scoring based on configurable criteria
- **CRM-03**: Unified customer timeline (support + sales)
- **CRM-04**: CRM automation workflows

### Advanced Automations

- **WKFL-01**: Visual workflow builder with drag-and-drop
- **WKFL-02**: Multi-step automation flows
- **WKFL-03**: AI-assisted chatbot flows

### Advanced Analytics

- **ANLR-09**: Scheduled automated report delivery
- **ANLR-10**: Customer-facing analytics portal

## Out of Scope

| Feature | Reason |
|---------|--------|
| Chatwoot API dependency | Own backend — fully independent |
| Non-WhatsApp channels in v1 | Focus on WhatsApp first, add channels in v2 |
| CRM pipeline | Deferred to v1.x after core is validated |
| AI chatbots | Deferred to v1.x |
| Mobile native apps | Responsive web first |
| Telephony / IVR | Not in roadmap — text-first platform |
| Payment processing | Outside core competency |
| Unlimited tenant customization | Curated options (logo, colors, domain) |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | — | Pending |
| AUTH-02 | — | Pending |
| AUTH-03 | — | Pending |
| AUTH-04 | — | Pending |
| AUTH-05 | — | Pending |
| AUTH-06 | — | Pending |
| ONBR-01 | — | Pending |
| ONBR-02 | — | Pending |
| ONBR-03 | — | Pending |
| ONBR-04 | — | Pending |
| WHTS-01 | — | Pending |
| WHTS-02 | — | Pending |
| WHTS-03 | — | Pending |
| WHTS-04 | — | Pending |
| WHTS-05 | — | Pending |
| WHTS-06 | — | Pending |
| WHTS-07 | — | Pending |
| WHTS-08 | — | Pending |
| WHTS-09 | — | Pending |
| INBX-01 | — | Pending |
| INBX-02 | — | Pending |
| INBX-03 | — | Pending |
| INBX-04 | — | Pending |
| INBX-05 | — | Pending |
| INBX-06 | — | Pending |
| INBX-07 | — | Pending |
| INBX-08 | — | Pending |
| INBX-09 | — | Pending |
| INBX-10 | — | Pending |
| INBX-11 | — | Pending |
| INBX-12 | — | Pending |
| CONT-01 | — | Pending |
| CONT-02 | — | Pending |
| CONT-03 | — | Pending |
| CONT-04 | — | Pending |
| CONT-05 | — | Pending |
| TEAM-01 | — | Pending |
| TEAM-02 | — | Pending |
| TEAM-03 | — | Pending |
| TEAM-04 | — | Pending |
| TEAM-05 | — | Pending |
| TEAM-06 | — | Pending |
| TEAM-07 | — | Pending |
| PERM-01 | — | Pending |
| PERM-02 | — | Pending |
| PERM-03 | — | Pending |
| PERM-04 | — | Pending |
| PERM-05 | — | Pending |
| WHTL-01 | — | Pending |
| WHTL-02 | — | Pending |
| WHTL-03 | — | Pending |
| WHTL-04 | — | Pending |
| WHTL-05 | — | Pending |
| ANLR-01 | — | Pending |
| ANLR-02 | — | Pending |
| ANLR-03 | — | Pending |
| ANLR-04 | — | Pending |
| ANLR-05 | — | Pending |
| ANLR-06 | — | Pending |
| ANLR-07 | — | Pending |
| ANLR-08 | — | Pending |
| AUTO-01 | — | Pending |
| AUTO-02 | — | Pending |
| AUTO-03 | — | Pending |
| AUTO-04 | — | Pending |
| UIUX-01 | — | Pending |
| UIUX-02 | — | Pending |
| UIUX-03 | — | Pending |
| UIUX-04 | — | Pending |
| UIUX-05 | — | Pending |

**Coverage:**
- v1 requirements: 65 total
- Mapped to phases: 0
- Unmapped: 65

---
*Requirements defined: 2026-02-11*
*Last updated: 2026-02-11 after architecture pivot (own backend)*
