# Roadmap: ChatWize

## Overview

ChatWize builds from foundation to full-featured multi-tenant WhatsApp customer support platform in four phases. Start with authentication and core architecture, add WhatsApp messaging and real-time capabilities, layer in team collaboration and permissions, then complete with white-label branding and analytics. Each phase delivers verifiable user-facing capabilities that enable the next.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3, 4): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation & Core Data** - Auth, multi-tenant architecture, database schema, UI framework
- [ ] **Phase 2: WhatsApp & Messaging Core** - WhatsApp integration, real-time messaging, basic inbox
- [ ] **Phase 3: Team Collaboration** - Teams, permissions, onboarding, advanced inbox features
- [ ] **Phase 4: White Label & Analytics** - Branding, dashboards, automation rules

## Phase Details

### Phase 1: Foundation & Core Data
**Goal**: Authenticated users can access multi-tenant platform with complete data isolation and modern UI
**Depends on**: Nothing (first phase)
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06, UIUX-01, UIUX-02, UIUX-03, UIUX-04, UIUX-05
**Success Criteria** (what must be TRUE):
  1. User can create account with email and password
  2. User receives email verification and can verify their account
  3. User can log in and session persists across browser restarts
  4. User can log out from any page
  5. User can reset password via email link
  6. Multi-tenant isolation enforced — user cannot access another tenant's data through any API endpoint
  7. UI works on desktop, tablet, and mobile devices
  8. UI supports light and dark mode
  9. Pages load under 3 seconds on standard connections
  10. UI displays in Portuguese (pt-BR)
**Plans**: TBD

Plans:
- [ ] 01-01: [To be planned]

### Phase 2: WhatsApp & Messaging Core
**Goal**: Agents can send and receive WhatsApp messages in real-time through unified inbox
**Depends on**: Phase 1
**Requirements**: WHTS-01, WHTS-02, WHTS-03, WHTS-04, WHTS-05, WHTS-06, WHTS-07, WHTS-08, WHTS-09, INBX-01, INBX-02, INBX-03, INBX-04, INBX-05, INBX-12, CONT-05
**Success Criteria** (what must be TRUE):
  1. Admin can connect WhatsApp via Cloud API (official)
  2. Admin can connect WhatsApp via Evolution API (non-official)
  3. Admin can connect WhatsApp via Waha API (non-official)
  4. System receives incoming WhatsApp messages from all three providers
  5. Agent can send outbound messages and see delivery status
  6. Agent can send and receive media files (images, documents, audio, video)
  7. Agent can view unified inbox with all conversations
  8. Agent can assign conversation to self, another agent, or team
  9. Agent can resolve, reopen, and snooze conversations
  10. Agent can add labels and priority to conversations
  11. Conversations update in real-time without page refresh
  12. System reconnects automatically on provider disconnection
  13. Contacts are auto-created from incoming WhatsApp messages
**Plans**: TBD

Plans:
- [ ] 02-01: [To be planned]

### Phase 3: Team Collaboration
**Goal**: Teams can collaborate on conversations with proper permissions and guided onboarding
**Depends on**: Phase 2
**Requirements**: TEAM-01, TEAM-02, TEAM-03, TEAM-04, TEAM-05, TEAM-06, TEAM-07, PERM-01, PERM-02, PERM-03, PERM-04, PERM-05, ONBR-01, ONBR-02, ONBR-03, ONBR-04, INBX-06, INBX-07, INBX-08, INBX-09, INBX-10, INBX-11, CONT-01, CONT-02, CONT-03, CONT-04
**Success Criteria** (what must be TRUE):
  1. Admin can create teams and invite agents by email
  2. Admin can assign roles (admin, supervisor, agent) with different permissions
  3. Admin can configure auto-assignment rules per team
  4. Admin can deactivate agents
  5. Agent can transfer conversation to another team or specific agent
  6. Admin has full access to all conversations and settings
  7. Supervisor can view all conversations in their teams
  8. Agent can only view conversations assigned to them or their team
  9. Permission rules are enforced at API level (not just UI)
  10. New tenant goes through guided onboarding after first login
  11. Onboarding includes connecting WhatsApp and creating first team
  12. Agent can add internal notes visible only to team
  13. Agent can use @mentions to notify other agents
  14. Agent can use canned responses for quick replies
  15. Agent can send and receive file attachments
  16. Agent can search conversations by keyword, contact, or status
  17. Agent can filter conversations by team, agent, status, label
  18. Agent can view contact profile with conversation history
  19. Agent can edit contact attributes (name, email, phone, custom fields)
  20. Agent can search, filter, and merge duplicate contacts
**Plans**: TBD

Plans:
- [ ] 03-01: [To be planned]

### Phase 4: White Label & Analytics
**Goal**: Tenants can brand platform as their own and analyze performance with actionable metrics
**Depends on**: Phase 3
**Requirements**: WHTL-01, WHTL-02, WHTL-03, WHTL-04, WHTL-05, ANLR-01, ANLR-02, ANLR-03, ANLR-04, ANLR-05, ANLR-06, ANLR-07, ANLR-08, AUTO-01, AUTO-02, AUTO-03, AUTO-04
**Success Criteria** (what must be TRUE):
  1. Admin can set custom logo, color theme, and favicon for their tenant
  2. Tenant branding stored in database and applied across all UI
  3. Admin can configure custom domain for their tenant
  4. Admin can view dashboard with conversation volume over time
  5. Admin can view average response time and resolution time
  6. Admin can view agent and team performance metrics
  7. Admin can filter analytics by date range, team, agent
  8. Admin can export reports to CSV and Excel
  9. Dashboards display modern charts
  10. Admin can create auto-assignment rules (round-robin, load-based)
  11. Admin can configure business hours per inbox
  12. Admin can set up auto-reply messages outside business hours
  13. Admin can create basic automation rules (if condition then action)
**Plans**: TBD

Plans:
- [ ] 04-01: [To be planned]

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Core Data | 0/TBD | Not started | - |
| 2. WhatsApp & Messaging Core | 0/TBD | Not started | - |
| 3. Team Collaboration | 0/TBD | Not started | - |
| 4. White Label & Analytics | 0/TBD | Not started | - |
