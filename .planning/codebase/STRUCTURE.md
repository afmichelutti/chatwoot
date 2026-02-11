# Codebase Structure

**Analysis Date:** 2026-02-11

## Directory Layout

```
chatwoot/
├── app/                          # Main application code
│   ├── channels/                 # ActionCable WebSocket channels
│   ├── controllers/              # HTTP request handlers
│   │   ├── api/
│   │   │   ├── v1/              # API v1 endpoints (primary)
│   │   │   └── v2/              # API v2 endpoints (newer features)
│   │   ├── application_controller.rb
│   │   ├── dashboard_controller.rb
│   │   └── [feature]/            # Feature-specific (Google, Twitter, etc.)
│   ├── javascript/               # Vue 3 SPA frontend
│   │   ├── dashboard/            # Main dashboard app
│   │   ├── sdk/                  # Widget SDK for embedding
│   │   ├── widget/               # Live chat widget
│   │   ├── portal/               # Help center portal
│   │   ├── superadmin_pages/     # Super admin UI
│   │   ├── survey/               # CSAT surveys
│   │   └── shared/               # Shared components & helpers
│   ├── jobs/                     # Sidekiq background jobs
│   ├── listeners/                # Event listeners for pub/sub
│   ├── dispatchers/              # Event dispatcher (sync/async)
│   ├── models/                   # ActiveRecord models
│   ├── services/                 # Business logic services
│   ├── builders/                 # Object builders (factories)
│   ├── policies/                 # Pundit authorization policies
│   ├── helpers/                  # View/controller helpers
│   ├── mailers/                  # Action Mailer email classes
│   ├── views/                    # ERB templates (minimal, mostly Vue)
│   ├── presenters/               # Serializers/presenters for responses
│   ├── actions/                  # Domain action classes
│   ├── assets/                   # Static assets
│   ├── fields/                   # Custom form field types
│   ├── finders/                  # Database query builders
│   ├── drops/                    # Liquid template drops
│   ├── mailboxes/                # ActionMailbox configuration
│   └── dashboards/               # Admin dashboards
├── config/                       # Rails configuration
│   ├── initializers/             # Rails initializers
│   ├── locales/                  # i18n translations
│   ├── environments/             # Environment-specific configs
│   ├── integration/              # Integration-specific configs
│   ├── routes.rb                 # Route definitions
│   ├── database.yml              # Database config
│   ├── application.rb            # Rails app configuration
│   └── [feature].yml             # Feature configs (features.yml, etc.)
├── db/                           # Database
│   ├── migrate/                  # ActiveRecord migrations
│   └── schema.rb                 # Current schema
├── lib/                          # Library code
│   ├── custom_exceptions/        # Custom exception classes
│   ├── integrations/             # Integration helpers
│   └── [utility]/                # Utility modules
├── enterprise/                   # Enterprise features (optional)
│   └── app/                      # Enterprise overrides/additions
├── spec/                         # RSpec tests (Ruby)
├── __mocks__/                    # Jest mocks
├── .circleci/                    # CircleCI CI/CD config
├── bin/                          # Executable scripts
├── public/                       # Static files, Vite output
├── tmp/                          # Temporary files
├── vendor/                       # Vendored gems/libraries
├── Gemfile                       # Ruby dependencies
├── package.json                  # Node.js dependencies
├── config.ru                     # Rack/Puma entry point
├── vite.config.js                # Vite bundler config
└── .env.example                  # Environment variables template
```

## Directory Purposes

**app/models/:**
- Purpose: Domain models with business logic and validations
- Contains: ActiveRecord classes representing database tables, associations, scopes, callbacks
- Key files: `account.rb`, `user.rb`, `conversation.rb`, `message.rb`, `contact.rb`, `inbox.rb`, `agent_bot.rb`
- Pattern: Models include concerns for shared behavior (e.g., `Labelable`, `ActivityMessageHandler`)

**app/services/:**
- Purpose: Business operation implementation
- Contains: Service classes that perform actions (filter, create, update, analyze conversations/contacts)
- Organized by: Domain (automation_rules/, contacts/, conversations/, integrations/)
- Key files: `action_service.rb` (conversation state changes), `automation_rules/action_service.rb` (rule execution)
- Pattern: Services initialized with context object(s), public methods for operations

**app/builders/:**
- Purpose: Complex object construction with validation
- Contains: Builder classes that assemble domain objects with full setup
- Key files: `account_builder.rb`, `conversation_builder.rb`, `contact_builder.rb`
- Pattern: Builders validate inputs, run transactions, return constructed objects

**app/controllers/api/v1/:**
- Purpose: RESTful endpoint handlers (primary API version)
- Contains: Versioned resource controllers (accounts, conversations, messages, agents, etc.)
- Structure: `accounts/` subdirectory for account-scoped resources
- Key files: `conversations_controller.rb`, `messages_controller.rb`, `agents_controller.rb`
- Pattern: Thin controllers - delegate to services/builders, check authorization

**app/controllers/api/v2/:**
- Purpose: API v2 endpoints (newer/alternative implementations)
- Contains: Updated endpoints with different response formats or capabilities
- Usage: New clients should use v2, v1 maintained for backward compatibility

**app/javascript/dashboard/:**
- Purpose: Main admin/agent dashboard Vue 3 application
- Contains: Components, routes, store modules, composables, helpers
- Structure:
  - `components/` - Reusable Vue components (ChatList, ChatHeader, etc.)
  - `store/modules/` - Vuex state management (conversations.js, agents.js, etc.)
  - `routes/` - Vue Router route definitions (dashboard.routes.js, etc.)
  - `composables/` - Vue 3 composition functions (useStore, useAccount, etc.)
  - `helper/` - JS utility functions (API calls, caching, auth)
  - `assets/` - Images, styles, icons
  - `App.vue` - Root component

**app/javascript/sdk/:**
- Purpose: Embedded widget SDK for customer websites
- Contains: Vue components compiled as standalone JavaScript library
- Output: `public/vite/assets/widget-*.js` and `public/packs/js/sdk.js`
- Usage: `<script>` tag embedded in customer websites for live chat

**app/javascript/shared/:**
- Purpose: Shared code across all frontends
- Contains: Common components (charts, dropdowns, UI elements), utilities, composables
- Key: UI design system components used across dashboard, widget, portal
- Location: `app/javascript/shared/components/` for reusable Vue components

**app/jobs/:**
- Purpose: Background job definitions for Sidekiq
- Contains: Job classes for async operations (sending emails, updating states, webhooks)
- Organization: Subdirectories by domain (conversations/, channels/, webhooks/)
- Key files: `send_reply_job.rb`, `webhook_job.rb`, `bulk_actions_job.rb`
- Pattern: Inherit from `ApplicationJob`, implement `perform(...)` method

**app/listeners/:**
- Purpose: Event listeners for domain event pub/sub
- Contains: Listeners that react to events dispatched by models
- Key files: `webhook_listener.rb`, `automation_rule_listener.rb`, `notification_listener.rb`
- Pattern: Inherit from `BaseListener`, implement event handler method
- Triggers: Events dispatched via `Dispatcher.dispatch('event.name', time, data)`

**app/policies/:**
- Purpose: Authorization rules via Pundit
- Contains: Policy classes defining what users can do with resources
- Pattern: `ResourcePolicy` class with methods like `index?`, `show?`, `update?`
- Authorization: Controllers call `authorize @resource` to enforce policies

**app/channels/:**
- Purpose: ActionCable WebSocket channel subscriptions
- Contains: Channel class defining subscription logic and broadcasts
- Key file: `room_channel.rb` - handles conversation/notification room subscriptions
- Pattern: Channel subscribers receive broadcasts when events are published

**config/initializers/:**
- Purpose: Rails initialization code run at startup
- Contains: Gem configuration, custom constants, library setup
- Key files: `devise.rb`, `redis.rb`, `sidekiq.rb`, `cors.rb`

**config/integration/:**
- Purpose: External service integration configurations
- Contains: API credentials, endpoint mappings, feature flags per service
- Usage: Loaded by services to connect to Slack, Facebook, WhatsApp, etc.

**db/migrate/:**
- Purpose: Database schema migrations
- Pattern: Numbered timestamp files with `change` or `up`/`down` methods
- Convention: One migration per feature/change

**lib/custom_exceptions/:**
- Purpose: Domain-specific exception classes
- Contains: Custom error classes inheriting from StandardError
- Pattern: Organized by domain (Account, Contact, Conversation, etc.)
- Usage: Raised by services, caught and formatted by controllers

## Key File Locations

**Entry Points:**
- `bin/rails` - Rails CLI entry point
- `bin/setup` - Development environment setup script
- `config.ru` - Rack app entry point (Puma server)
- `app/javascript/entrypoints/dashboard.js` - Frontend initialization
- `app/controllers/dashboard_controller.rb` - SPA root page

**Configuration:**
- `.env` / `.env.example` - Environment variables
- `config/routes.rb` - Route definitions (22MB - extensive routing)
- `config/application.rb` - Rails app configuration and initializers
- `config/features.yml` - Feature flag definitions
- `Gemfile` / `package.json` - Dependencies

**Core Business Logic:**
- `app/models/account.rb` - Multi-tenant account model
- `app/models/conversation.rb` - Conversation state and events
- `app/models/message.rb` - Individual messages in conversations
- `app/models/user.rb` - Agent/admin users
- `app/models/contact.rb` - Customer contacts
- `app/models/inbox.rb` - Communication channels (Email, WhatsApp, etc.)
- `app/models/channel/` - Channel implementations (Facebook, Instagram, etc.)

**API Layer:**
- `app/controllers/application_controller.rb` - Base controller (auth, context setup)
- `app/controllers/api/base_controller.rb` - API controller base (error handling)
- `app/controllers/api/v1/accounts_controller.rb` - Account management
- `app/controllers/api/v1/conversations_controller.rb` - Conversation CRUD
- `app/controllers/api/v1/messages_controller.rb` - Message operations

**Testing:**
- `spec/` - RSpec test files (mirrors app/ structure)
- `__mocks__/` - Jest mock definitions
- `vitest.config.js` - Frontend test config

## Naming Conventions

**Files:**
- Controllers: `{resource}_controller.rb` (e.g., `conversations_controller.rb`)
- Models: `{entity}.rb` singular (e.g., `conversation.rb`, `account.rb`)
- Services: `{entity}_{action}_service.rb` (e.g., `conversation_filter_service.rb`)
- Jobs: `{action}_{entity}_job.rb` (e.g., `send_reply_job.rb`)
- Builders: `{entity}_builder.rb` (e.g., `conversation_builder.rb`)
- Policies: `{entity}_policy.rb` (e.g., `conversation_policy.rb`)
- Vue components: PascalCase, `.vue` extension (e.g., `ChatList.vue`, `MessageItem.vue`)
- Store modules: camelCase, `.js` extension (e.g., `conversations.js`, `agents.js`)

**Directories:**
- Feature directories snake_case (e.g., `automation_rules/`, `help_center/`)
- API versions prefixed (e.g., `/api/v1/`, `/api/v2/`)
- Account-scoped routes nested under accounts (e.g., `/accounts/{id}/conversations/`)

## Where to Add New Code

**New Conversation Feature (e.g., priority levels):**
- Model logic: `app/models/conversation.rb` - add priority field, validations, scope
- Migration: `db/migrate/YYYYMMDDHHMMSS_add_priority_to_conversations.rb`
- Service: `app/services/conversations/priority_service.rb` - handle priority operations
- API: `app/controllers/api/v1/conversations_controller.rb` - expose via endpoint
- Event listener: `app/listeners/conversation_priority_listener.rb` - react to priority changes
- Frontend: `app/javascript/dashboard/store/modules/conversations.js` - store priority state
- Frontend: `app/javascript/dashboard/components/ConversationPriority.vue` - UI component
- Tests: `spec/services/conversations/priority_service_spec.rb` and Vue tests in `__mocks__/`

**New Agent Bot Capability:**
- Model: Extend `app/models/agent_bot.rb` with new capability
- Service: `app/services/agent_bots/new_capability_service.rb` - implement logic
- Job: `app/jobs/agent_bots/new_capability_job.rb` - background execution if needed
- API: Add endpoint in `app/controllers/api/v1/accounts/agent_bots_controller.rb`
- Tests: Corresponding spec files in `spec/`

**New Integration (e.g., Salesforce CRM):**
- Service: `app/services/integrations/salesforce/client.rb` - API client
- Service: `app/services/integrations/salesforce/sync_service.rb` - data synchronization
- Model: Extend `app/models/account.rb` to store integration credentials
- Job: `app/jobs/integrations/salesforce_sync_job.rb` - scheduled sync
- Listener: `app/listeners/salesforce_sync_listener.rb` - react to events (create contact, etc.)
- Config: `config/integration/salesforce.yml` - integration config
- Tests: `spec/services/integrations/salesforce/` directory

**New API Endpoint:**
- Controller: `app/controllers/api/v1/{resource}_controller.rb`
- Route: Add to `config/routes.rb` under appropriate namespace
- Policy: `app/policies/{resource}_policy.rb` - authorization
- Serializer/Presenter: Define response format in controller or separate presenter
- Tests: `spec/requests/api/v1/{resource}_spec.rb`

**New Vue Component:**
- Component: `app/javascript/dashboard/components/{FeatureName}/{ComponentName}.vue`
- Store module: `app/javascript/dashboard/store/modules/{entity}.js` if new domain
- Composable: `app/javascript/dashboard/composables/use{Feature}.js` if shared logic
- Helper: `app/javascript/dashboard/helper/{feature}Helper.js` for utilities
- Tests: Co-locate as `{ComponentName}.spec.js` or in `__mocks__/`

**Shared Utilities:**
- JavaScript: `app/javascript/shared/` for components/helpers used across frontends
- Ruby: `lib/` for library code, `lib/custom_exceptions/` for domain exceptions
- Constants: `app/javascript/shared/constants/` or `app/javascript/dashboard/constants/`

## Special Directories

**enterprise/:**
- Purpose: Enterprise edition overrides and additional features
- Generated: No, checked into git
- Committed: Yes, part of codebase
- Usage: Automatically loaded alongside standard app/ via `config/application.rb`
- Pattern: Mirrors app/ structure - overrides are loaded after standard code

**public/:**
- Purpose: Static files and compiled assets
- Generated: Yes (Vite builds here)
- Committed: No (except .gitkeep)
- Contents: `vite/` for bundled JS/CSS, `packs/` for older asset pipeline

**tmp/:**
- Purpose: Runtime temporary files
- Generated: Yes
- Committed: No

**vendor/:**
- Purpose: Vendored gems and libraries
- Generated: No (managed by bundler)
- Committed: No

**.planning/codebase/:**
- Purpose: GSD codebase analysis documents
- Location: Root `.planning/codebase/` directory
- Files: ARCHITECTURE.md, STRUCTURE.md, CONVENTIONS.md, TESTING.md, CONCERNS.md, STACK.md, INTEGRATIONS.md
- Usage: Referenced by `/gsd:plan-phase` and `/gsd:execute-phase` commands

---

*Structure analysis: 2026-02-11*
