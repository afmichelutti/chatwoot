# External Integrations

**Analysis Date:** 2026-02-11

## APIs & External Services

**Social Media Channels:**
- Facebook Messenger - Incoming/outgoing messages
  - SDK/Client: `facebook-messenger` gem
  - Auth: `FB_APP_ID`, `FB_APP_SECRET`, `FB_VERIFY_TOKEN`
  - Models: `Channel::FacebookPage` at `app/models/channel/facebook_page.rb`

- Instagram - Instagram direct messaging
  - SDK/Client: `koala` gem (Facebook Graph API)
  - Auth: `IG_VERIFY_TOKEN` (inherited from Facebook setup)
  - Models: `Channel::Instagram` at `app/models/channel/instagram.rb`

- Twitter - Tweet replies and DMs
  - SDK/Client: `twitty` gem (Twitter API 1.1 wrapper)
  - Auth: `TWITTER_APP_ID`, `TWITTER_CONSUMER_KEY`, `TWITTER_CONSUMER_SECRET`, `TWITTER_ENVIRONMENT`
  - Models: `Channel::TwitterProfile` at `app/models/channel/twitter_profile.rb`

- Slack - Team communication
  - SDK/Client: `slack-ruby-client` 2.7.0
  - Auth: `SLACK_CLIENT_ID`, `SLACK_CLIENT_SECRET` (OAuth flow)
  - Integration: `app/controllers/slack_*` and OmniAuth providers

- LINE Messaging - LINE chat integration
  - SDK/Client: `line-bot-api` gem
  - Models: `Channel::Line` at `app/models/channel/line.rb`

- Telegram - Telegram bot messaging
  - SDK/Client: Native integration
  - Models: `Channel::Telegram` at `app/models/channel/telegram.rb`

- WhatsApp - WhatsApp messaging via cloud API
  - SDK/Client: HTTP client (faraday/rest-client)
  - Models: `Channel::Whatsapp` at `app/models/channel/whatsapp.rb`
  - Config: WhatsApp Cloud API management and i18n support

**SMS & Voice:**
- Twilio - SMS and voice calls
  - SDK/Client: `twilio-ruby` gem
  - Auth: Configured via Twilio account credentials
  - Models: `Channel::TwilioSms` at `app/models/channel/twilio_sms.rb`

- Generic SMS - Basic SMS channel
  - Models: `Channel::Sms` at `app/models/channel/sms.rb`

**Ecommerce & Integrations:**
- Shopify - Ecommerce platform integration
  - SDK/Client: `shopify_api` gem
  - Purpose: Storefront chat and customer communication

**Authentication Providers:**
- Google OAuth2 - Single sign-on
  - SDK/Client: `omniauth-google-oauth2` 1.1.3+
  - Auth: `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET`, `GOOGLE_OAUTH_CALLBACK_URL`
  - Implementation: OmniAuth provider in `config/initializers/omniauth.rb`

- Microsoft Azure - Azure AD/Microsoft 365 authentication
  - SDK/Client: `omniauth-oauth2`
  - Auth: `AZURE_APP_ID`, `AZURE_APP_SECRET`
  - Implementation: OAuth2 provider in OmniAuth

- SAML - Enterprise single sign-on
  - SDK/Client: `omniauth-saml` gem
  - Use cases: Corporate LDAP/directory integration

## Data Storage

**Databases:**
- PostgreSQL (primary)
  - Connection: `POSTGRES_HOST`, `POSTGRES_USERNAME`, `POSTGRES_PASSWORD`, `POSTGRES_DATABASE`
  - Client: ActiveRecord (Rails ORM)
  - Config file: `config/database.yml`
  - Features: pgvector extension for vector search, full-text search support

**File Storage:**
- Active Storage (abstraction layer)
  - Config: `ACTIVE_STORAGE_SERVICE` (default: `local`)
  - AWS S3
    - Environment: `S3_BUCKET_NAME`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`
    - SDK: `aws-sdk-s3` gem
  - Google Cloud Storage
    - SDK: `google-cloud-storage` 1.48.0+ gem
  - Azure Blob Storage
    - SDK: `azure-storage-blob` gem (custom fork from chatwoot)
  - Local filesystem (development/simple deployments)
    - No additional configuration needed

**Caching & Sessions:**
- Redis
  - Connection: `REDIS_URL` or individual `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`
  - Alternative: Redis Sentinel for high availability (`REDIS_SENTINELS`, `REDIS_SENTINEL_MASTER_NAME`)
  - SDK: `redis` gem with `redis-namespace` for key organization
  - Use cases: Session store, cache backend, Sidekiq queue backing, ActionCable channel data
  - Config file: `config/cable.yml` for ActionCable WebSocket support

**Search:**
- Elasticsearch/OpenSearch
  - SDK: `opensearch-ruby` gem for OpenSearch, `searchkick` for integration
  - Auth: AWS SigV4 authentication via `faraday_middleware-aws-sigv4`
  - Purpose: Full-text search on conversations, articles, knowledge base
  - Optional: Can be disabled, falls back to PostgreSQL search

## Authentication & Identity

**Auth Provider:**
- Custom Devise-based authentication (primary)
  - Implementation: `devise` 4.9.4+, `devise_token_auth` 1.2.3+
  - Features: Token-based API auth, 2FA via `devise-two-factor` 5.0.0+
  - Enhanced security: `devise-secure_password` (custom fork)
  - Database encryption: Active Record Encryption for 2FA secrets

- Multi-provider OAuth (secondary)
  - Google OAuth2 - Standard OpenID Connect flow
  - Microsoft Azure - OAuth2 for M365 tenants
  - SAML - Enterprise SSO via `omniauth-saml`

**Two-Factor Authentication:**
- TOTP (Time-based One-Time Password) via `devise-two-factor`
- Active Record encrypted storage for OTP secrets
- Required env vars: `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY`, `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`

## Monitoring & Observability

**Error Tracking:**
- Sentry (optional, env-gated)
  - SDK: `sentry-rails` 5.19.0+, `sentry-ruby`, `sentry-sidekiq` 5.19.0+
  - Auth: `SENTRY_DSN`
  - Config: `config/initializers/sentry.rb`
  - Features: Exception tracking, performance transactions (10% sample rate), PII tracking (configurable)

**APM & Performance:**
- Datadog (optional, env-gated)
  - SDK: `datadog` gem 2.0
  - Auth: `DD_TRACE_AGENT_URL`
  - Features: Distributed tracing, metrics collection
  - Config: `config/initializers/datadog.rb`

- Elastic APM (optional, env-gated)
  - SDK: `elastic-apm` gem
  - Auth: `ELASTIC_APM_SERVER_URL`, `ELASTIC_APM_SECRET_TOKEN`
  - Config: `config/elastic_apm.yml`

- New Relic (optional, env-gated)
  - SDK: `newrelic_rpm`, `newrelic-sidekiq-metrics` 1.6.2+
  - Auth: `NEW_RELIC_LICENSE_KEY`
  - Config: `config/newrelic.yml`

- Scout APM (optional, env-gated)
  - SDK: `scout_apm` gem
  - Auth: `SCOUT_KEY`, `SCOUT_NAME`
  - Config: `config/scout_apm.yml`

**Logs:**
- File/stdout logging (standard Rails)
  - Output: Configurable via `RAILS_LOG_TO_STDOUT`, `LOG_LEVEL`, `LOG_SIZE`
  - Optional Lograge integration: `lograge` 0.14.0 gem for structured logging

**Product Analytics:**
- PostHog
  - SDK: `posthog-js` 1.260.2
  - Purpose: Feature analytics, product insights, feature flags

## CI/CD & Deployment

**Hosting:**
- Multi-platform support:
  - Docker containers (custom Dockerfile with Node.js/pnpm for asset precompilation)
  - Heroku (with heroku-specific gems like `judoscale-rails`, `judoscale-sidekiq`, `barnes`)
  - Standard VPS/cloud deployments (any Ruby-compatible host)

**CI Pipeline:**
- CircleCI (configured in `.circleci/config.yml`)
- GitHub workflows (Dependabot in `.dependabot/config.yml`)

**Process Management:**
- Foreman - Local development with `Procfile.dev`
- Overmind - Alternative process manager for local development
- Puma - Rails production server
- Sidekiq 7.3.1+ - Background job processor
- Sidekiq Alive - Health check endpoint for Sidekiq

## Environment Configuration

**Required env vars (Core):**
- `SECRET_KEY_BASE` - Rails session/cookie encryption (generate with `rake secret`)
- `FRONTEND_URL` - Public-facing application URL
- `RAILS_ENV` - Environment (development/test/production)
- `POSTGRES_*` - Database connection details
- `REDIS_URL` or `REDIS_HOST/PORT/PASSWORD` - Cache and job queue

**Integration env vars:**
- Stripe: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`
- OpenAI: `OPENAI_API_KEY` (optional, for AI features)
- Google: `GOOGLE_OAUTH_CLIENT_ID`, `GOOGLE_OAUTH_CLIENT_SECRET`, `GOOGLE_OAUTH_CALLBACK_URL`
- Azure: `AZURE_APP_ID`, `AZURE_APP_SECRET`
- Slack: `SLACK_CLIENT_ID`, `SLACK_CLIENT_SECRET`
- Facebook: `FB_APP_ID`, `FB_APP_SECRET`, `FB_VERIFY_TOKEN`, `IG_VERIFY_TOKEN`
- Twitter: `TWITTER_APP_ID`, `TWITTER_CONSUMER_KEY`, `TWITTER_CONSUMER_SECRET`, `TWITTER_ENVIRONMENT`
- AWS: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `S3_BUCKET_NAME`
- GCS: Service account credentials (file-based)
- Azure Storage: Connection string or credentials
- Sentry: `SENTRY_DSN`
- Datadog: `DD_TRACE_AGENT_URL`
- New Relic: `NEW_RELIC_LICENSE_KEY`

**Secrets location:**
- `.env` files (local development) - git-ignored
- Environment variables (production/cloud platforms)
- Docker secrets (containerized deployments)
- Cloud provider secret managers (AWS Secrets Manager, Azure Key Vault, etc.)

## Webhooks & Callbacks

**Incoming Webhooks:**
- Facebook Messenger - `POST /webhooks/facebook` (Facebook callback for messages)
- Twitter - `POST /webhooks/twitter` (Twitter webhook subscription)
- Slack - OAuth callback at `SLACK_CLIENT_*` configured URL
- Stripe - `POST /webhooks/stripe` for payment events
- Email inbound - Rails Action Mailbox with multiple providers:
  - Mailgun: `POST /rails/action_mailbox/mailgun/inbound_emails`
  - Postmark: `POST /rails/action_mailbox/postmark/inbound_emails`
  - Sendgrid: `POST /rails/action_mailbox/sendgrid/inbound_emails`
  - Mandrill: `POST /rails/action_mailbox/mandrill/inbound_emails`
  - Exim/Postfix relay: Local ingestion
  - Auth: `RAILS_INBOUND_EMAIL_PASSWORD` for HTTP auth

**Outgoing Webhooks:**
- Channel message delivery to social platforms
- Conversation updates to external systems
- Stripe payment webhooks - Event subscriptions configured via Stripe dashboard

**Callback URLs:**
- Google OAuth: `GOOGLE_OAUTH_CALLBACK_URL` - Redirect after Google login
- Facebook/Instagram: Webhook verification via `FB_VERIFY_TOKEN` and `IG_VERIFY_TOKEN`

## Rate Limiting & Security

**Request Throttling:**
- Rack Attack 6.7.0+ gem for rate limiting
  - Config: `ENABLE_RACK_ATTACK`, `RACK_ATTACK_LIMIT` (default 300 req/min)
  - Widget API throttling: `ENABLE_RACK_ATTACK_WIDGET_API`
  - Trusted IPs bypass: `RACK_ATTACK_ALLOWED_IPS` (comma-separated)

**CORS:**
- Rack CORS 2.0.0 middleware enabled
- Configurable origins for cross-origin requests

**CSRF Protection:**
- Rails CSRF protection enabled by default
- Special handling for OmniAuth: `omniauth-rails_csrf_protection` 1.0.2+

## Geolocation & IP Services

**IP Geolocation:**
- GeoIP2 via Geocoder gem
  - Config: `IP_LOOKUP_API_KEY` (MaxMind account)
  - Database: `GeocoderConfiguration::LOOK_UP_DB` local database file
  - Purpose: IP-based location detection for analytics, auto-routing

## Mobile & Push Notifications

**Push Notifications:**
- Firebase Cloud Messaging (FCM)
  - SDK: `fcm` gem
  - Auth: `FCM_SERVER_KEY` (Firebase project credentials)

- Web Push (standard)
  - SDK: `web-push` 3.0.1+ gem
  - Auth: `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY` (generate via VAPID key generator)

- Mobile Push Relay
  - Custom relay server for official mobile apps
  - Config: `ENABLE_PUSH_RELAY_SERVER`

**Mobile App SDK:**
- Official iOS app: `L7YLMN4634.com.chatwoot.app`
- Official Android app: `com.chatwoot.app`
- Android certificate: `ANDROID_SHA256_CERT_FINGERPRINT` (from Play Store)

## Third-Party Integrations

**AI & NLU:**
- Google Dialogflow - Conversational AI
  - SDK: `google-cloud-dialogflow-v2` 0.24.0+ gem
  - Purpose: Intent recognition, NLU for automation

- OpenAI - GPT language models
  - SDK: `ruby-openai` gem
  - Auth: `OPENAI_API_KEY`
  - Use cases: AI-powered responses, conversation summarization
  - Infrastructure: `ai-agents` 0.4.3+ for agentic workflows, `ruby_llm-schema` for type definitions

**Translation:**
- Google Cloud Translation API
  - SDK: `google-cloud-translate-v3` 0.7.0+ gem
  - Purpose: Multi-language conversation support

**Payments & Billing:**
- Stripe - Payment processing and subscriptions
  - SDK: `stripe` gem
  - Auth: `STRIPE_SECRET_KEY` (API key)
  - Webhook: `STRIPE_WEBHOOK_SECRET` (webhook signing)
  - Config: `config/initializers/stripe.rb`
  - Use cases: Billing, subscription management, payment collection

---

*Integration audit: 2026-02-11*
