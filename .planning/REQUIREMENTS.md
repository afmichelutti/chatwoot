# Requirements: Chatwoot Fork — v4.11.1 Upgrade & Security Audit

**Defined:** 2026-02-21
**Core Value:** Agents can only access conversations they are authorized to see, with no data leakage through any interface.

## v1 Requirements

Requirements for this milestone. Each maps to roadmap phases.

### Upgrade

- [ ] **UPGR-01**: Fork is upgraded to Chatwoot v4.11.1 via git merge
- [ ] **UPGR-02**: All merge conflicts are resolved preserving custom modifications
- [ ] **UPGR-03**: Activity-Based Presence system preserved and functional after merge
- [ ] **UPGR-04**: White-label branding customization preserved and functional after merge
- [ ] **UPGR-05**: WhatsApp Cloud API config management preserved and functional after merge
- [ ] **UPGR-06**: Corrupted conversation handling preserved and functional after merge
- [ ] **UPGR-07**: Permission enforcement code reconciled (upstream Pundit authorize vs custom PermissionFilterService)
- [ ] **UPGR-08**: All new upstream database migrations run successfully
- [ ] **UPGR-09**: Application boots correctly with all services (Rails, Sidekiq, Vite)
- [ ] **UPGR-10**: pt-BR translations preserved and merged with upstream changes
- [ ] **UPGR-11**: Dev scripts (start/stop .bat, setup-dev.sh) still functional

### Security — Conversation Isolation

- [ ] **SECR-01**: Agent cannot access conversations assigned to other agents via direct URL
- [ ] **SECR-02**: Agent cannot see other agents' conversations in the Contacts tab conversation history
- [ ] **SECR-03**: Agent cannot reassign conversations from other agents to themselves
- [ ] **SECR-04**: Agent cannot see other agents' conversations via search endpoint
- [ ] **SECR-05**: Agent cannot see other agents' conversations via filter endpoint
- [ ] **SECR-06**: Agent cannot access other agents' conversation data via WebSocket events
- [ ] **SECR-07**: Agent cannot see other agents' conversations via contact profile API
- [ ] **SECR-08**: All conversation-related API endpoints enforce permission checks at controller level
- [ ] **SECR-09**: Permission checks use Pundit policies consistently (not mixed approaches)
- [ ] **SECR-10**: Conversation assignment endpoint validates that the assigner has permission to the conversation

### Testing

- [ ] **TEST-01**: RSpec tests cover agent accessing own conversation (allowed)
- [ ] **TEST-02**: RSpec tests cover agent accessing other agent's conversation via direct endpoint (denied)
- [ ] **TEST-03**: RSpec tests cover agent viewing contact conversation history filtered by permissions
- [ ] **TEST-04**: RSpec tests cover agent attempting to reassign other agent's conversation (denied)
- [ ] **TEST-05**: RSpec tests cover search endpoint respecting permission boundaries
- [ ] **TEST-06**: RSpec tests cover filter endpoint respecting permission boundaries
- [ ] **TEST-07**: RSpec tests cover supervisor seeing team conversations (allowed)
- [ ] **TEST-08**: RSpec tests cover admin seeing all conversations (allowed)

## v2 Requirements

Deferred to future milestone. Tracked but not in current roadmap.

### Performance

- **PERF-01**: Benchmark permission filter impact on response times
- **PERF-02**: Add caching for permission lookups on high-traffic endpoints

### Advanced Security

- **ASEC-01**: Audit trail for permission violations (log unauthorized access attempts)
- **ASEC-02**: Rate limiting on conversation access endpoints
- **ASEC-03**: CSRF protection audit across all mutation endpoints

## Out of Scope

| Feature | Reason |
|---------|--------|
| New feature development | This milestone is upgrade + security only |
| ChatWize (Next.js project) | Separate project, deferred |
| New channels | No new channels in this milestone |
| UI redesign | Preserve existing customizations |
| Upgrading beyond v4.11.1 | One version jump at a time |
| Frontend permission enforcement | UI filtering is a bonus, API enforcement is the requirement |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| UPGR-01 | TBD | Pending |
| UPGR-02 | TBD | Pending |
| UPGR-03 | TBD | Pending |
| UPGR-04 | TBD | Pending |
| UPGR-05 | TBD | Pending |
| UPGR-06 | TBD | Pending |
| UPGR-07 | TBD | Pending |
| UPGR-08 | TBD | Pending |
| UPGR-09 | TBD | Pending |
| UPGR-10 | TBD | Pending |
| UPGR-11 | TBD | Pending |
| SECR-01 | TBD | Pending |
| SECR-02 | TBD | Pending |
| SECR-03 | TBD | Pending |
| SECR-04 | TBD | Pending |
| SECR-05 | TBD | Pending |
| SECR-06 | TBD | Pending |
| SECR-07 | TBD | Pending |
| SECR-08 | TBD | Pending |
| SECR-09 | TBD | Pending |
| SECR-10 | TBD | Pending |
| TEST-01 | TBD | Pending |
| TEST-02 | TBD | Pending |
| TEST-03 | TBD | Pending |
| TEST-04 | TBD | Pending |
| TEST-05 | TBD | Pending |
| TEST-06 | TBD | Pending |
| TEST-07 | TBD | Pending |
| TEST-08 | TBD | Pending |

**Coverage:**
- v1 requirements: 29 total
- Mapped to phases: 0
- Unmapped: 29 (pending roadmap creation)

---
*Requirements defined: 2026-02-21*
*Last updated: 2026-02-21 after initial definition*
