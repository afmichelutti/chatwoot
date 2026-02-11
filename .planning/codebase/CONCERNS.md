# Codebase Concerns

**Analysis Date:** 2026-02-11

## Tech Debt

**Default Scopes in Models:**
- Issue: Multiple models use `default_scope`, which causes unpredictable query behavior and requires explicit `reorder()` calls
- Files: `app/models/message.rb` (line 125), `app/models/installation_config.rb` (line 29)
- Impact: Risk of silent bugs when querying without reorder; confusion when developers expect specific ordering
- Fix approach: Remove default scopes and apply ordering explicitly at query sites. Prioritize `Message` model first due to frequency of use

**Sidekiq Worker Uses Old Queue Framework:**
- Issue: `ConversationReplyEmailWorker` uses Sidekiq directly instead of Rails ActiveJob
- Files: `app/workers/conversation_reply_email_worker.rb` (line 1)
- Impact: Inconsistent job handling with rest of codebase; harder to maintain unified job interface
- Fix approach: Migrate to ActiveJob like other workers in codebase

**YAML Serialization Security Risk:**
- Issue: `InstallationConfig` uses YAML serialization with `ActiveSupport::HashWithIndifferentAccess` - potential RCE vector if user input is serialized
- Files: `app/models/installation_config.rb` (line 22)
- Impact: Known CVE-2022-32224 - YAML deserialization can lead to code execution in older Rails
- Fix approach: Migrate to JSON serialization; ensure only trusted data is deserialized

**Broad Rescue Clauses:**
- Issue: Many files catch `StandardError` and log silently without re-raising or proper handling
- Files: `app/controllers/api/v1/accounts/callbacks_controller.rb` (multiple), `app/builders/messages/facebook/message_builder.rb`, `app/jobs/inboxes/fetch_imap_emails_job.rb` (line 20)
- Impact: Errors are swallowed; makes debugging difficult; can hide critical failures
- Fix approach: Use specific exception types; add proper logging with error context; avoid silent failures

---

## Known Bugs

**Corrupted Conversation Records (Contact Inbox Orphan):**
- Symptoms: Requesting conversation list returns 500 error; NoMethodError when serializing conversation
- Files: `app/models/message.rb` (lines 166-179), affected conversations documented in `docs/md/troubleshooting_corrupted_conversations.md`
- Trigger: Conversations with `contact_id` present but `contact_inbox_id = NULL`; likely from incomplete transaction during creation
- Current mitigation: `message.rb` now checks `if conversation.contact_inbox.present?` before accessing source_id (defensive fix applied)
- Workaround: Manually mark corrupted conversations as resolved via console; use diagnostic scripts

**Permission Bypass with conversation_participating_manage Role:**
- Symptoms: Agents with limited `conversation_participating_manage` permission could access unassigned conversations via direct URL or contact history
- Files: `app/controllers/api/v1/accounts/conversations_controller.rb` (now includes check_conversation_permission! method); `app/services/conversations/permission_filter_service.rb`
- Trigger: Controller only verified inbox access, not individual conversation permission
- Fix applied: Added `check_conversation_permission!` method that filters via PermissionFilterService before returning 403 Forbidden if unauthorized
- Status: Fix implemented and tested locally (Dec 2025)

**Timing Bug in Message Attachment Sending:**
- Symptoms: Attachments may not be fully uploaded before job processes message
- Files: `app/models/message.rb` (line 371-373)
- Trigger: ActiveStorage commits file after transaction; job scheduled immediately
- Current mitigation: 2-second delay hardcoded with comment "FIXME"
- Fix approach: Either wait for ActiveStorage callback or implement proper file readiness check

---

## Security Considerations

**Encryption Configuration Dependency:**
- Risk: Many models conditionally encrypt sensitive data only if `Chatwoot.encryption_configured?`
- Files: `app/models/channel/instagram.rb` (line 23), `app/models/channel/line.rb` (lines 23-24), `app/models/channel/telegram.rb` (line 21), `app/models/integrations/hook.rb` (line 25)
- Current mitigation: Encryption is optional and may not be enabled; environment variables used as fallback
- Recommendations: Make encryption mandatory; audit all production deployments verify encryption is enabled; add warning in logs if encryption disabled

**VAPID Keys Deprecation:**
- Risk: System still falls back to environment variables for VAPID keys when database keys don't exist
- Files: `lib/vapid_service.rb` (lines 16-18)
- Current mitigation: System generates and saves keys if missing
- Recommendations: Remove ENV variable fallback after confirming all installations have migrated; enforce database-only key storage

**Token Storage in Models:**
- Risk: Access tokens, bot tokens, and credentials stored with conditional encryption
- Files: Multiple channel models (`app/models/channel/telegram.rb`, `app/models/channel/facebook_page.rb`, etc.)
- Current mitigation: Encryption applied when available; tokens marked as deterministic for lookups
- Recommendations: Implement token rotation; audit token access logs; implement rate limiting on token endpoints

**InstallationConfig YAML Injection:**
- Risk: If `serialized_value` can be influenced by user input, YAML deserialization could be exploited
- Files: `app/models/installation_config.rb` (line 22)
- Recommendations: Verify that InstallationConfig values come only from super admin; add serialization validation

---

## Performance Bottlenecks

**CSAT Survey Response Queries on Messages Table:**
- Problem: Querying CSAT survey responses requires scanning full messages table and checking `content_type: 'csat'`
- Files: `db/migrate/20250627195529_add_index_to_messages.rb` (lines 5-12)
- Cause: Survey data embedded in messages; no dedicated survey table
- Improvement path: Create `csat_surveys` table; populate when surveys sent; query dedicated table instead of messages (referenced in migration TODO)
- Impact: Significant query time with millions of messages; temporary index added as band-aid

**N+1 Query Patterns Not Fully Addressed:**
- Problem: Controllers retrieve conversations and serialize via push_event_data which may load related records without eager loading
- Files: `app/models/message.rb` (conversation_push_event_data), many API controllers
- Cause: Polymorphic sender associations; nested contact_inbox; unread message counts
- Improvement path: Add consistent eager loading in conversation finders; profile serialization path

**Default Scope Ordering Overhead:**
- Problem: Message.default_scope orders by created_at ascending on every query; developers must remember to reorder
- Files: `app/models/message.rb` (line 125)
- Cause: Design choice that leaks implementation details to query sites
- Improvement path: Remove default scope; add scopes for common ordering patterns (latest_first, earliest_first)

---

## Fragile Areas

**Message Model Complexity:**
- Files: `app/models/message.rb` (462 lines)
- Why fragile: Core model handling multiple concerns - content types, attachments, CSAT surveys, search indexing, serialization, reply sending; extensive state transitions
- Safe modification: Use feature branches; run full message spec suite; test with real inbox operations (email, WhatsApp, etc.)
- Test coverage: Has comprehensive spec file (`spec/models/message_spec.rb`) but gaps around attachment handling and corrupted data

**Conversation Model Core Logic:**
- Files: `app/models/conversation.rb` (323 lines)
- Why fragile: Orchestrates assignment, automation, notifications, status transitions; heavy callback dependencies
- Safe modification: Test both individual conversation changes and bulk operations (filters, exports); verify webhook events fire correctly
- Test coverage: Good spec coverage but permission check recently added (Dec 2025) shows vulnerability

**Permission Filter Service - Recent Addition:**
- Files: `app/services/conversations/permission_filter_service.rb` (30 lines)
- Why fragile: Recently added security fix; only filters based on inbox access - may have edge cases
- Safe modification: Add tests for all role types; test with contact history endpoints; verify API still returns correct data
- Test coverage: Currently relies on manual test scripts (`test_permission_fix.rb`, `test_open_unassigned_conversation.rb`)

**WhatsApp Integration Stack:**
- Files: `app/services/whatsapp/*` (multiple large services: 226, 196, 171, 190 lines each)
- Why fragile: Multiple providers (Cloud, 360Dialog), version-specific APIs, token refresh logic, message type conversions
- Safe modification: Test each provider separately; verify webhook delivery; test template parameter handling
- Test coverage: Has specs but complex service interactions require integration tests

**Email Channel Operations:**
- Files: `app/models/channel/email.rb`, `app/services/inboxes/fetch_imap_emails_job.rb`
- Why fragile: IMAP connection state management; retry logic for network failures; password encryption/decryption
- Safe modification: Test with real email accounts; verify attachment handling; test error recovery paths
- Test coverage: Moderate - basic tests exist but edge cases around network failures not fully covered

**Database Relationship Integrity:**
- Files: All models (no foreign key constraints observed to require contact_inbox_id presence)
- Why fragile: Corrupted data can slip in and cause 500 errors; defensive coding needed everywhere
- Safe modification: Add database-level constraints; audit existing data; implement data validation jobs
- Test coverage: Mostly absent - need more defensive tests around missing related records

---

## Scaling Limits

**Message Table Growth:**
- Current capacity: Millions of messages (system appears to handle ~millions based on migration context)
- Limit: CSAT queries timeout with millions of messages; index added as workaround
- Scaling path: Dedicated CSAT survey table; implement message archival/partitioning; pagination-based queries only

**Conversation Filtering Performance:**
- Current capacity: ~10k active conversations per account typical
- Limit: Complex filter queries with multiple JOIN conditions may timeout; archived conversations remain in table
- Scaling path: Implement conversation archival table; use Elasticsearch for large account searches (already integrated); add query result pagination

**Redis Presence Tracking:**
- Current capacity: Active users stored in Redis; no documented limits
- Limit: Real-time presence broadcast may degrade with 1000+ concurrent users
- Scaling path: Implement presence aggregation; move to dedicated presence service; batch websocket broadcasts

**WebSocket Connection Limits:**
- Current capacity: ActionCable handles concurrent connections; no explicit limits documented
- Limit: Broadcasting to thousands of connections may cause latency
- Scaling path: Implement stream filtering; use Redis adapter for distributed deployments; scale horizontally

---

## Dependencies at Risk

**Sidekiq Version Lock:**
- Risk: ConversationReplyEmailWorker uses direct Sidekiq API; future Sidekiq versions may change
- Impact: Worker may break if Sidekiq upgraded significantly
- Migration plan: Rewrite as ActiveJob immediately to decouple from Sidekiq specifics

**YAML Serialization in Rails:**
- Risk: Rails moving away from YAML serialization; security concerns with Psych deserialization
- Impact: InstallationConfig model will break in Rails 8+
- Migration plan: Migrate to JSON serialization before major Rails upgrade

**Searchkick/Elasticsearch Integration:**
- Risk: Search functionality conditionally enabled based on `ChatwootApp.advanced_search_allowed?`
- Impact: If condition changes unexpectedly, search quality degrades silently
- Migration plan: Make search adapter pluggable; add health checks; implement fallback to database search

---

## Missing Critical Features

**Data Validation at Database Level:**
- Problem: Conversations can have null contact_inbox_id despite needing it for serialization
- Blocks: Cannot guarantee data integrity; serialization must be defensive everywhere
- Recommendation: Add database constraints for required relationships

**Conversation Archival System:**
- Problem: Old conversations never deleted; table grows unbounded; old queries slow down
- Blocks: Cannot efficiently handle years of conversation history
- Recommendation: Implement archival/purge policy; create archive table; age-based soft-deletes

**Comprehensive Audit Logging:**
- Problem: Permission changes and data access not fully audited
- Blocks: Cannot trace who accessed what conversation; security incident investigation difficult
- Recommendation: Implement unified audit log; log all conversation access; track permission changes

**Test Coverage for Permission Checks:**
- Problem: Permission bypasses found via manual testing, not automated tests
- Blocks: Cannot prevent regression on permission fixes
- Recommendation: Add automated tests for each role type; test permission matrix; integrate into CI

---

## Test Coverage Gaps

**Corrupted Data Scenarios:**
- What's not tested: Handling of nil contact_inbox, nil contact, nil inbox relationships
- Files: `app/models/conversation.rb`, `app/models/message.rb`, serializers
- Risk: 500 errors in production when data corruption occurs
- Priority: HIGH - add fixture for corrupted conversations; test serialization with missing relationships

**Permission Filtering Edge Cases:**
- What's not tested: Custom roles with partial permissions; bulk operations on filtered conversations; API consistency
- Files: `app/services/conversations/permission_filter_service.rb`, controllers using it
- Risk: Permission bypasses like Dec 2025 incident could recur
- Priority: HIGH - add comprehensive role-based permission matrix tests; test all endpoints with each role

**WhatsApp Provider Fallback:**
- What's not tested: Switching between WhatsApp Cloud and 360Dialog; token refresh failure handling; provider-specific errors
- Files: `app/services/whatsapp/*` services
- Risk: Messages fail silently or error handling diverges between providers
- Priority: MEDIUM - add provider-specific test suites; test provider detection logic

**Email Attachment Processing:**
- What's not tested: Large attachments (>25MB); corrupted MIME; concurrent attachment processing
- Files: `app/services/inboxes/fetch_imap_emails_job.rb`, attachment handling
- Risk: Email processing hangs or crashes with edge case files
- Priority: MEDIUM - add large file tests; test malformed MIME; test concurrent processing

**Automation Rules Condition Matching:**
- What's not tested: Complex nested conditions; performance with 1000+ rules; rule ordering impact
- Files: `app/services/automation_rules/conditions_filter_service.rb` (209 lines)
- Risk: Automation rules don't trigger or trigger incorrectly; rules slow down message processing
- Priority: MEDIUM - add complex condition tests; benchmark rule evaluation; test rule precedence

---

## Technical Debt Summary by Priority

| Priority | Area | Impact | Effort |
|----------|------|--------|--------|
| HIGH | Remove default scopes | Silent bugs, complexity | 4-6 hours |
| HIGH | Add corrupted data tests | Production errors | 2-3 hours |
| HIGH | Comprehensive permission tests | Security regressions | 4-5 hours |
| MEDIUM | Migrate YAML to JSON (InstallationConfig) | Security + Rails 8 compat | 2-3 hours |
| MEDIUM | Migrate Sidekiq worker to ActiveJob | Code consistency | 1-2 hours |
| MEDIUM | Implement CSAT survey table | Query performance | 4-6 hours |
| MEDIUM | Add audit logging | Security visibility | 3-4 hours |
| MEDIUM | Improve WhatsApp test coverage | Reliability | 3-4 hours |
| LOW | Improve message attachment reliability | Edge cases | 2-3 hours |
| LOW | Implement conversation archival | Scaling | 6-8 hours |

---

*Concerns audit: 2026-02-11*
