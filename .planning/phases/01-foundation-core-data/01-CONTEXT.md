# Phase 1: Foundation & Core Data - Context

**Gathered:** 2026-02-21
**Status:** Ready for planning

> **NOTE:** This context document was updated on 2026-02-21 to reflect the actual Phase 1 scope:
> upgrading the Chatwoot fork from v4.7.0-custom to v4.11.1 via git merge.
> The previous content (SaaS multi-tenant build with auth/sidebar/theming) was from a prior
> project scope and does not apply to this phase.

<domain>
## Phase Boundary

Git merge of upstream Chatwoot v4.11.1 into the v4.7.0-custom fork branch. Resolve all 11 merge conflicts preserving custom modifications (Activity-Based Presence, WhatsApp Cloud API config, white-label branding, corrupted conversation handling, pt-BR translations, dev scripts). Run database migrations, verify application boots, and document the permission approach decision (upstream Pundit authorize vs custom PermissionFilterService). This phase delivers a fully merged, bootable codebase -- no new features, no security hardening (that is Phase 2).

</domain>

<decisions>
## Implementation Decisions

### Merge Strategy
- Git merge (not rebase) of v4.11.1 tag into v4.7.0-custom branch
- Create backup branch (v4.7.0-custom-backup) before merge for safety
- Resolve conflicts in two waves: backend/config first, then frontend/branding
- Use `--no-commit` to allow conflict resolution before finalizing

### Conflict Resolution Approach
- conversations_controller.rb: Keep BOTH upstream authorize fix AND custom PermissionFilterService (complementary)
- channel/whatsapp.rb: Accept upstream, merge custom Cloud API config methods on top
- schedule.yml: Accept upstream, preserve custom presence jobs
- db/schema.rb: Accept upstream entirely (custom migrations re-run separately)
- Frontend WhatsApp files: Accept upstream, preserve custom additions
- Branding files (logos, colors): Keep ours (custom white-label is the point)
- pt-BR translations: Accept upstream structure, overlay our translations

### Permission Approach
- Decision deferred to Plan 03 Task 2 for formal evaluation
- Likely outcome: keep both Pundit authorize + PermissionFilterService (defense in depth)
- Phase 2 (Security Audit) will unify the pattern

### Auto-Merged File Verification
- conversation.rb and message.rb: Verify corrupted conversation handling survived auto-merge
- account.rb and user.rb: Verify Activity-Based Presence code survived auto-merge
- These files are not in the conflict list but contain critical custom code

### Claude's Discretion
- Order of conflict resolution within each wave
- Whether to use `git checkout --ours` vs manual editing per conflict file
- How to handle unexpected merge artifacts in auto-merged files

</decisions>

<specifics>
## Specific Ideas

- Merge commit message should document all 11 conflict resolutions for traceability
- Backup branch enables easy rollback if post-merge issues discovered
- Separate plans for backend vs frontend conflicts keeps each plan focused

</specifics>

<deferred>
## Deferred Ideas

- Security hardening of permission system (Phase 2)
- New feature development (out of scope for this milestone)
- Frontend permission enforcement in UI (out of scope)

</deferred>

---

*Phase: 01-foundation-core-data*
*Context gathered: 2026-02-21 (replaced stale context from prior project scope)*
