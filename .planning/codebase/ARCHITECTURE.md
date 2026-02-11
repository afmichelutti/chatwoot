# Architecture

**Analysis Date:** 2026-02-11

## Pattern Overview

**Overall:** Rails 7 monolith with Vue 3 SPA frontend, event-driven backend, and real-time WebSocket communication via ActionCable.

**Key Characteristics:**
- **MVC on Rails backend** with service layer abstraction for business logic
- **Event-driven architecture** using dispatcher pattern for async/sync event handling
- **Vue 3 single-page application (SPA)** with Vuex store for state management
- **Real-time updates** via ActionCable WebSocket channel broadcasts
- **Multi-tenant** with account-scoped API routes and authorization via Pundit policies
- **Omnichannel** - multiple communication channels (Email, Facebook, Instagram, WhatsApp, Telegram, SMS, etc.) abstracted through channel models

## Layers

**Presentation Layer (Frontend):**
- Purpose: Render UI and handle user interactions
- Location: `app/javascript/dashboard/` - Vue 3 components, routes, and Vuex store
- Contains: Vue components (`.vue` files), composables, routes, store modules
- Depends on: API endpoints, ActionCable WebSocket for real-time updates
- Used by: End users in browser

**API Layer (Backend - Controllers):**
- Purpose: Accept HTTP requests and route to business logic
- Location: `app/controllers/api/v1/` and `app/controllers/api/v2/`
- Contains: RESTful controllers (e.g., `accounts_controller.rb`, `conversations_controller.rb`), authentication middleware
- Depends on: Services, Models, Policies (authorization)
- Used by: Frontend SPA, mobile apps, webhooks

**Business Logic Layer (Services):**
- Purpose: Encapsulate domain operations and workflows
- Location: `app/services/` - organized by domain (e.g., `automation_rules/`, `conversations/`, `contacts/`)
- Contains: Service classes that implement specific actions (e.g., `ActionService` for conversation state changes, `ConversationBuilder` for creating conversations)
- Depends on: Models, external APIs, Redis
- Used by: Controllers, Jobs, Event Listeners

**Data Persistence Layer (Models):**
- Purpose: Define data structures and domain logic
- Location: `app/models/` - ActiveRecord models with associations and validations
- Contains: Domain models (Account, User, Conversation, Message, Contact, etc.), associations, scopes, validations
- Depends on: Database (PostgreSQL), Redis for caching
- Used by: Services, Controllers, Events

**Event System (Pub/Sub):**
- Purpose: Decouple components via event-driven updates
- Location: `app/listeners/` and `app/dispatchers/`
- Contains: Event listeners (webhook, automation, notification, reporting), dispatcher (sync/async)
- Depends on: Event payloads from Models and Controllers
- Used by: All layers for state propagation

**Real-Time Communication:**
- Purpose: Push updates to connected clients
- Location: `app/channels/` (ActionCable channels)
- Contains: WebSocket channel subscriptions for real-time conversation/notification updates
- Depends on: Redis pub/sub, ActionCable
- Used by: Frontend subscribed to conversation rooms

**Job Queue (Background Processing):**
- Purpose: Async task execution
- Location: `app/jobs/` - Sidekiq jobs organized by domain
- Contains: Job classes (e.g., `SendReplyJob`, `WebhookJob`, `BulkActionsJob`)
- Depends on: Redis, Models, Services
- Used by: Delayed action execution, integrations, bulk operations

**Integration Layer:**
- Purpose: Handle external service communication
- Location: `app/services/` subdirectories for specific integrations (e.g., `crm/`, `integrations/`)
- Contains: API clients for Slack, Facebook, WhatsApp, Shopify, CRM systems
- Depends on: HTTP clients (Faraday), Redis for token storage
- Used by: Services and Controllers for channel functionality

## Data Flow

**Incoming Customer Message (External Channel):**

1. Webhook/Channel API receives message from Facebook, WhatsApp, etc.
2. Channel-specific webhook controller (`FacebookMessagesController`, `WhatsAppWebhookController`) receives request
3. Message builder transforms channel data to internal format (e.g., `FacebookMessageBuilder`)
4. Message model created with conversation link
5. `Dispatcher.dispatch('message.created', timestamp, {message: msg, account: account})`
6. Event listeners triggered:
   - `WebhookListener` - sends outgoing webhooks
   - `NotificationListener` - creates user notifications
   - `ReportingEventListener` - logs metrics
   - `AutomationRuleListener` - evaluates automation rules
7. `ActionCableListener` broadcasts message to subscribers in conversation room
8. Frontend receives WebSocket update and renders message

**Agent Sending Reply:**

1. Frontend sends POST to `/api/v1/accounts/{id}/conversations/{id}/messages`
2. API controller validates request and calls `ActionService`
3. `ActionService#send_message` or `SendReplyJob` creates message and sends to channel
4. `ChannelService.send_message_on_channel` invokes channel-specific handler
5. Message queued in Sidekiq job for channel delivery
6. Once delivered, message listeners trigger same event cycle
7. Conversation `last_activity_at` updated, triggering assignment/automation rules
8. WebSocket broadcast updates all subscribers

**Conversation Status Change:**

1. Frontend dispatches Vuex action to update conversation
2. API POST to `/api/v1/accounts/{id}/conversations/{id}/custom_actions`
3. Controller calls `ActionService` with action (resolve, mute, assign_agent, etc.)
4. `ActionService` updates conversation status
5. `Conversation.status_changed` callback dispatches event
6. Event listeners process (webhooks, automations, notifications)
7. WebSocket broadcasts to all subscribers in conversation room
8. All connected clients receive real-time update

**State Management (Frontend):**
- User actions in Vue components dispatch Vuex store actions
- Store actions call API endpoints
- API success responses update store mutations
- Store state triggers component re-renders
- WebSocket messages also update store (bypassing API latency)

## Key Abstractions

**Channel Model Pattern:**
- Purpose: Abstraction for omnichannel support
- Examples: `Channel::Email`, `Channel::FacebookPage`, `Channel::WhatsApp`, `Channel::WebWidget`, `Channel::Telegram`
- Pattern: Each channel inherits from `Channel` base, implements `send_message` and message reception
- Allows: New channels added without changing core conversation logic

**Builder Pattern:**
- Purpose: Complex object construction with validation
- Examples: `AccountBuilder`, `ConversationBuilder`, `MessageBuilder`, `ContactBuilder`
- Pattern: Builders validate inputs, handle transactions, return constructed objects
- Benefit: Keeps controller thin, centralizes business rules

**Service Pattern:**
- Purpose: Business operation encapsulation
- Examples: `ActionService` (conversation state), `ContactFilterService` (contact filtering), `AutomationRuleService` (rule execution)
- Pattern: Service initialized with context (conversation, contact, account), performs work via public methods
- Benefit: Reusable across controllers and jobs

**Event Listener Pattern:**
- Purpose: Reactive operations triggered by domain events
- Examples: `WebhookListener`, `AutomationRuleListener`, `NotificationListener`
- Pattern: Listeners subscribe to events, extract data via `extract_*_and_account` helper, perform side effects
- Benefit: Decouples features, allows independent evolution

**Vuex Store Modules:**
- Purpose: Compartmentalized state management
- Examples: `store/modules/conversations.js`, `store/modules/agents.js`, `store/modules/contacts.js`
- Pattern: Each module manages its domain state (state, getters, mutations, actions)
- Benefit: Scalable state organization, action dispatching to API

## Entry Points

**Web Application:**
- Location: `app/controllers/dashboard_controller.rb`
- Triggers: Browser GET `/app` or `/app/*`
- Responsibilities: Renders SPA root HTML, loads initial account/user context
- Frontend entry: `app/javascript/entrypoints/dashboard.js` → initializes Vue app with router/store

**API Endpoints:**
- Location: `config/routes.rb` and `app/controllers/api/v1/`, `app/controllers/api/v2/`
- Triggers: HTTP requests to `/api/v1/*` or `/api/v2/*`
- Responsibilities: RESTful operations on resources (accounts, conversations, messages, agents, etc.)
- Authentication: Devise token auth middleware

**Webhooks (Inbound):**
- Location: `app/controllers/webhooks/` - channel-specific webhook handlers
- Triggers: External service (Facebook, WhatsApp, Twilio) POST to `/webhooks/*`
- Responsibilities: Parse channel payload, create message/contact, trigger event listeners
- Examples: `FacebookMessagesController`, `InstagramMessagesController`, `TwilioSmsController`

**Background Jobs:**
- Location: `app/jobs/application_job.rb` and subclasses
- Triggers: Enqueued via `SomeJob.perform_later` from controllers/services
- Responsibilities: Long-running tasks, retries, error handling
- Execution: Sidekiq worker pool processes from Redis queue

**ActionCable (WebSocket):**
- Location: `app/channels/room_channel.rb` and `app/channels/application_cable/`
- Triggers: Browser WebSocket connection to ActionCable server
- Responsibilities: Subscribe clients to conversation/notification rooms, broadcast updates
- Broadcast sources: Event listeners trigger `ActionCableListener` → broadcasts

## Error Handling

**Strategy:** Layered approach with exception handlers and graceful degradation

**Patterns:**
- **Custom exceptions** (`lib/custom_exceptions/`) for domain-specific errors (AccountNotFound, InvalidEmail, etc.)
- **Rescue in controllers** via `rescue_from` to catch and format errors as JSON
- **Rescue in jobs** with retry logic and failure callbacks
- **Database transactions** in builders to rollback on failure
- **Validation in models** with `validates` to prevent invalid state

**Exception Hierarchy:**
- `StandardError` → Rails HTTP response (status codes, JSON messages)
- Custom exceptions caught at controller level → error responses with detailed messages
- Job exceptions trigger retries (exponential backoff) then dead-letter queue

## Cross-Cutting Concerns

**Logging:**
- Rails logger to file/stdout
- APM tools (New Relic, Datadog, Elastic, Scout) for production monitoring
- Exception tracking (Sentry) for error aggregation

**Validation:**
- ActiveRecord validations in models
- JSON schema validation via `json_schemer` gem
- Service-layer validation before persisting

**Authentication:**
- Devise for user account management
- Devise token auth for API client auth (mobile, external systems)
- JWT tokens stored in client cookies/headers

**Authorization:**
- Pundit authorization library with policy classes in `app/policies/`
- Policy checks in controllers via `authorize` method
- Account-scoped access - users only see their account's data
- Role-based access (administrator, agent, custom_role) enforced via policies

**Caching:**
- Fragment caching for expensive queries
- Redis-backed cache for account settings, feature flags
- Cache invalidation on model updates

**Multitenancy:**
- Account isolation - all queries scoped to current account
- `Current.account` thread-local for request context
- Account ID in URL path (`/api/v1/accounts/{id}/...`)

---

*Architecture analysis: 2026-02-11*
