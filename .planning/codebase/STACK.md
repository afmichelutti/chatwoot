# Technology Stack

**Analysis Date:** 2026-02-11

## Languages

**Primary:**
- Ruby 3.4.4 - Backend Rails application, business logic, and channel integrations
- JavaScript/TypeScript - Frontend Vue 3 SPA and component libraries
- Vue 3 - Frontend UI framework and component development

**Secondary:**
- SQL (PostgreSQL) - Data persistence
- SCSS/CSS - Styling with Tailwind CSS

## Runtime

**Environment:**
- Ruby on Rails 7.1 - Web framework and HTTP server
- Node.js 20.5.1 (from .nvmrc) - JavaScript runtime for frontend and build tools
- Puma - Rails application server (configured via Gemfile)

**Package Manager:**
- pnpm 10.x - JavaScript/Node package manager
- Bundler - Ruby gem package manager
- Lockfile: `pnpm-lock.yaml` and `Gemfile.lock` present

## Frameworks

**Core:**
- Rails 7.1 - Web framework with ActiveRecord ORM
- Vue 3 5.x - Progressive frontend framework
- Vite 5.4.20 - Frontend build tool and dev server
- Vite Rails - Rails/Vite integration plugin

**Testing:**
- Vitest 3.0.5 - JavaScript/Vue component testing framework (runs with TZ=UTC for consistency)
- RSpec Rails 6.x - Ruby testing framework
- Factory Bot Rails 6.4.3+ - Test data factories for Ruby models

**Build/Dev:**
- Foreman - Process manager for development (Procfile.dev)
- Overmind - Alternative process manager
- Husky 7.0.0+ - Git hooks for pre-push validation
- Rubocop - Ruby linter and code formatter
- ESLint 8.57.0 - JavaScript/Vue linter (extends airbnb-base/legacy, vue3-recommended)
- Prettier 3.3.3 - Code formatter (80 char printWidth, single quotes, trailing commas)

## Key Dependencies

**Critical:**
- PostgreSQL adapter (pg) - Database driver for Rails
- Redis 7.x - Caching, session storage, and Sidekiq job queue backing
- Sidekiq 7.3.1+ - Background job processing
- Sidekiq-cron 1.12.0+ - Scheduled job management
- ActionCable - WebSocket support for real-time updates

**Frontend Core:**
- Vue Router 4.4.5 - Client-side routing
- Vuex 4.1.0 - State management
- Vuex Router Sync 6.0.0-rc.1 - Syncs router state to Vuex store
- Axios 1.8.2 - HTTP client for API calls
- Vue I18n 9.14.5 - Internationalization
- Tailwind CSS 3.4.13 - Utility-first CSS framework

**Frontend UI Components:**
- Vue Multiselect 3.1.0 - Dropdown/autocomplete component
- Floating Vue 5.2.2 - Popover/tooltip positioning
- TanStack Vue Table 8.20.5 - Data table/grid management
- Vue DatePicker Next 1.0.3 - Date input component
- Vue Virtual Scroller 2.0.0-beta.8 - Large list virtualization
- Vuedraggable 4.1.0 - Drag-and-drop for Vue components
- Highlight.js 11.10.0 - Code syntax highlighting

**Media & Recording:**
- Video.js 7.18.1 - Video player library
- Videojs-record 4.5.0 - Recording capabilities
- Videojs-wavesurfer 3.8.0 - Audio waveform visualization
- Wavesurfer.js 7.8.6 - Audio waveform rendering
- Opus Recorder 8.0.5 - Audio recording in browser
- QRCode 1.5.4 - QR code generation

**Data & Utilities:**
- Chart.js 4.4.4 + Vue-chartjs 5.3.1 - Data visualization
- date-fns 2.21.1 + date-fns-tz 1.3.3 - Date manipulation and timezones
- Markdown-it 13.0.2 - Markdown parsing and rendering
- DOMPurify 3.2.4 - HTML sanitization for XSS prevention
- libphonenumber-js 1.11.9 - Phone number parsing and formatting
- Countries-and-timezones 3.6.0 - Timezone/country data

**Validation & Schema:**
- Vuelidate 2.0.3+ - Vue form validation library
- JSON Logic JS 2.0.5 - JSON-based rule evaluation

**Accessibility & Localization:**
- @hcaptcha/vue3-hcaptcha 1.3.0 - hCaptcha CAPTCHA component
- Iconify Vue plugin with JSON icon sets - Icon library system

**Error Tracking & Analytics:**
- Sentry (sentry-rails, sentry-ruby, sentry-sidekiq) 5.19.0+ - Error monitoring (optional, env-gated)
- @sentry/vue 8.31.0 - Sentry integration for Vue
- PostHog 1.260.2 - Product analytics and feature flags

**Infrastructure & Cloud:**
- aws-sdk-s3 - AWS S3 integration for file storage
- google-cloud-storage 1.48.0+ - Google Cloud Storage integration
- azure-storage-blob (custom fork) - Azure Blob Storage integration
- down - Safe remote file downloading

**APM & Observability:**
- Datadog 2.0 (optional, env-gated) - APM and monitoring
- Elastic APM (optional, env-gated) - Elasticsearch APM agent
- New Relic RPM (optional, env-gated) - Application performance monitoring
- Scout APM (optional, env-gated) - Performance monitoring
- Barnes - Heroku metrics reporting

**Database & Search:**
- Searchkick - Elasticsearch/OpenSearch integration
- OpenSearch Ruby client - OpenSearch access
- Faraday Middleware AWS SigV4 - AWS signature authentication for Elasticsearch
- ActiveRecord Import - Bulk record insertion
- pg_search - PostgreSQL full-text search
- Neighbor + pgvector - Vector search for AI features
- Groupdate - Time-based grouping queries
- Redis Namespace - Key-based Redis organization

**Authentication & Authorization:**
- Devise 4.9.4+ - User authentication
- Devise Token Auth 1.2.3+ - Token-based API authentication
- Devise Two-Factor 5.0.0+ - 2FA/MFA support
- Devise Secure Password (custom fork) - Enhanced password security
- Pundit - Authorization/policy framework
- JWT - JSON Web Token support
- OmniAuth 2.1.2+ - Multi-provider authentication
- OmniAuth Google OAuth2 1.1.3+ - Google login
- OmniAuth SAML - SAML authentication
- OmniAuth OAuth2 - Generic OAuth2 provider support
- OmniAuth Rails CSRF Protection 1.0.2+ - CSRF safety for OmniAuth

**Channel Integrations:**
- facebook-messenger - Facebook Messenger SDK
- line-bot-api - LINE messaging API
- twilio-ruby - Twilio SMS/voice integration
- twitty 0.1.5 - Twitter API wrapper
- koala - Facebook Graph API client
- slack-ruby-client 2.7.0 - Slack API client

**Cloud AI & Translation:**
- google-cloud-dialogflow-v2 0.24.0+ - Google Dialogflow NLU
- google-cloud-translate-v3 0.7.0+ - Google Cloud Translation API
- ruby-openai - OpenAI GPT API client
- ai-agents 0.4.3+ - AI agent framework
- ruby_llm-schema - LLM schema definitions

**Billing & Commerce:**
- Stripe - Payment processing and billing
- Shopify API - Shopify integration

**Utilities & Helpers:**
- Liquid - Template engine for email/content
- Kaminari - Pagination
- Responders - DRY Rails response handling
- Rest Client - HTTP client library
- Jbuilder - JSON response templating
- Administrate 0.20.1+ - Admin dashboard framework
- Audited 5.4.1+ - Model change auditing
- Email Reply Trimmer - Email quote trimming
- HTML2Text - HTML to text conversion
- Reverse Markdown - HTML to Markdown conversion
- Common Marker - CommonMark markdown parsing
- JSON Schemer - JSON schema validation
- Geocoder - Geolocation services
- MaxMindDB - GeoIP database access
- Working Hours - Business hour calculations
- Hairtrigger - Database trigger management
- Rack CORS 2.0.0 - CORS middleware
- Rack Attack 6.7.0+ - Request rate limiting
- CSV Safe - CSV injection prevention
- Flag Shih Tzu - Feature flag implementation
- Haikunator - Random name generation
- Hashie - Hash utilities
- Telephone Number - Phone number validation
- Time Diff - Time difference calculations
- TZInfo Data - Timezone database
- Browser - User agent detection
- Acts as Taggable On - Tagging system

**Development Tools:**
- Annotate - ActiveRecord schema annotations
- Bullet - N+1 query detection
- Letter Opener - Preview emails in browser
- Rack Mini Profiler 3.2.0+ - Request profiling
- StackProf - Ruby profiling
- Meta Request - Rails query inspection
- Tidewave - Database visualization
- Webmock - HTTP mocking for tests
- Database Cleaner - Test database cleaning
- Test Prof - Test profiling
- Brakeman - Security vulnerability scanning
- Bundle Audit - Gem vulnerability auditing
- Byebug - Ruby debugger
- Climate Control - Environment variable mocking
- Debug 1.8+ - Ruby debugging
- Pry Rails - Ruby REPL
- Shoulda Matchers - RSpec test helpers
- SimpleCov 0.21+ - Code coverage reporting
- Seed Dump - Database seeding
- Spring - Rails application preloader
- Rubocop (Performance, Rails, RSpec, Factory Bot variants) - Code quality

## Configuration

**Environment:**
- Loads from `.env` files via dotenv-rails 3.0.0+
- Key configs: RAILS_ENV, REDIS_URL, POSTGRES_* vars, STRIPE_SECRET_KEY, OPENAI_API_KEY, etc.
- See `.env.example` for full configuration reference

**Build:**
- `vite.config.ts` - Vite build configuration with library mode support for SDK
- `tailwind.config.js` - Tailwind CSS customization
- `.eslintrc.js` - ESLint configuration (Vue 3, Vitest, i18n rules)
- `.prettierrc` - Prettier formatting rules (80 char width, single quotes)
- `.ruby-version` - Ruby version specification (3.4.4)
- `.nvmrc` - Node version specification (20.5.1)

## Platform Requirements

**Development:**
- Ruby 3.4.4
- Node.js 20.5.1
- PostgreSQL 12+
- Redis 6+
- pnpm 10.x as package manager
- Docker & Docker Compose (for containerized development)

**Production:**
- Rails 7.1 application server (Puma)
- PostgreSQL database
- Redis for caching and Sidekiq
- Object storage (AWS S3, Google Cloud Storage, or Azure Blob Storage)
- Supports Heroku, Docker, or standard VPS deployment
- Optional APM: Datadog, Elastic APM, New Relic, Scout, or Sentry
- Sidekiq workers for background jobs (can run in separate processes/containers)

**Infrastructure Features:**
- WebSocket support via ActionCable for real-time features
- Rack timeout protection in production
- Heroku auto-scaling support (judoscale)
- Health checks for Sidekiq (sidekiq_alive)

---

*Stack analysis: 2026-02-11*
