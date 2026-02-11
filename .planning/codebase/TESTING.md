# Testing Patterns

**Analysis Date:** 2026-02-11

## Test Framework

**Frontend Runner:**
- Vitest (configured in `vite.config.ts`)
- Version: Latest (configured via vite)
- Config: `vite.config.ts` with test section
- Environment: jsdom (DOM simulation)

**Backend Runner:**
- RSpec (Rails testing framework)
- Config: `spec/test_helper.rb`
- Fixtures: Configured in test_helper for all test files

**Assertion Library:**
- JavaScript: Vitest built-in assertions + Chai (implicit)
- Ruby: RSpec matchers

**Run Commands:**
```bash
npm test                    # Run all JavaScript tests (no watch, no coverage)
npm run test:watch         # Watch mode for JavaScript tests
npm run test:coverage      # Generate coverage reports
bundle exec rspec          # Run all Ruby tests (typical convention)
TZ=UTC vitest             # Run tests with UTC timezone explicitly
```

## Test File Organization

**Frontend Location:**
- Co-located with source files
- Pattern: `specs/` directories at component level or `*.spec.js` alongside source
- Examples:
  - `app/javascript/dashboard/api/specs/account.spec.js`
  - `app/javascript/dashboard/components/app/specs/`
  - `app/javascript/dashboard/composables/commands/spec/useAppearanceHotKeys.spec.js`

**Backend Location:**
- Centralized in `spec/` directory at project root
- Pattern: mirrors source structure under `app/`
- Example: `app/actions/contact_identify_action.rb` → `spec/services/contact_identify_action_spec.rb`

**Naming:**
- JavaScript: `*.spec.js` or `*.test.js`
- Ruby: `*_spec.rb`

**Structure:**
```
app/javascript/dashboard/
├── api/
│   ├── account.js
│   ├── ApiClient.js
│   └── specs/
│       ├── account.spec.js
│       └── ApiClient.spec.js (if exists)
├── components/
│   └── app/
│       ├── AddAccountModal.vue
│       └── specs/
│           └── AddAccountModal.spec.js (if exists)
```

## Test Structure

**Suite Organization - JavaScript:**
```javascript
import accountAPI from '../account';
import ApiClient from '../ApiClient';

describe('#accountAPI', () => {
  it('creates correct instance', () => {
    expect(accountAPI).toBeInstanceOf(ApiClient);
    expect(accountAPI).toHaveProperty('get');
  });

  describe('API calls', () => {
    // Nested suite for related tests
    it('#createAccount', () => {
      // Test implementation
    });
  });
});
```

**Suite Organization - Ruby:**
```ruby
require 'rails_helper'

describe ContactIdentifyAction do
  subject(:contact_identify) { described_class.new(contact: contact, params: params).perform }

  let!(:account) { create(:account) }
  let(:custom_attributes) { { test: 'test' } }
  let!(:contact) { create(:contact, account: account, custom_attributes: custom_attributes) }

  describe '#perform' do
    it 'updates the contact' do
      contact_identify
      expect(contact.reload.name).to eq 'test'
    end
  end
end
```

**Patterns:**
- `describe` blocks for grouping related tests
- `it` blocks for individual test cases
- Nested `describe` blocks for organization (e.g., API calls, edge cases)
- Clear test descriptions: "#methodName" or "when [condition]"
- One assertion per test preferred, but related assertions allowed

## Mocking

**Framework:**
- JavaScript: `vi` (Vitest globals)
- Ruby: RSpec mocks and stubs

**Patterns - JavaScript:**
```javascript
describe('API calls', () => {
  const originalAxios = window.axios;
  const axiosMock = {
    post: vi.fn(() => Promise.resolve()),
    get: vi.fn(() => Promise.resolve()),
    patch: vi.fn(() => Promise.resolve()),
    delete: vi.fn(() => Promise.resolve()),
  };

  beforeEach(() => {
    window.axios = axiosMock;
  });

  afterEach(() => {
    window.axios = originalAxios;
  });

  it('#createAccount', () => {
    accountAPI.createAccount({ name: 'Chatwoot' });
    expect(axiosMock.post).toHaveBeenCalledWith('/api/v1/accounts', {
      name: 'Chatwoot',
    });
  });
});
```

**Patterns - Ruby:**
```ruby
it 'enqueues avatar job when valid avatar url parameter is passed' do
  params = { name: 'test', avatar_url: 'https://chatwoot-assets.local/sample.png' }
  expect(Avatar::AvatarFromUrlJob).to receive(:perform_later).with(contact, params[:avatar_url]).once
  described_class.new(contact: contact, params: params).perform
end

it 'does not enqueue avatar job when invalid avatar url parameter is passed' do
  params = { name: 'test', avatar_url: 'invalid-url' }
  expect(Avatar::AvatarFromUrlJob).not_to receive(:perform_later)
  described_class.new(contact: contact, params: params).perform
end
```

**What to Mock:**
- External HTTP calls (axios, API clients)
- Background jobs (Avatar::AvatarFromUrlJob)
- Third-party services
- Global objects when testing isolated units

**What NOT to Mock:**
- Model validations
- Database operations (use fixtures/factories instead)
- Core business logic
- Integration tests should use real database

## Fixtures and Factories

**Test Data - Ruby:**
```ruby
let!(:account) { create(:account) }
let(:custom_attributes) { { test: 'test', test1: 'test1' } }
let!(:contact) { create(:contact, account: account, custom_attributes: custom_attributes) }
let(:params) do
  { name: 'test', identifier: 'test_id',
    additional_attributes: { location: 'Bengaulru', company_name: 'Meta' },
    custom_attributes: { test: 'new test', test2: 'test2' } }
end
```

**Patterns:**
- `let` for lazy-evaluated variables (evaluated when needed)
- `let!` for immediate creation (used for associations)
- `create()` factory method from FactoryBot (inferred from `factory` gem)
- Reusable fixtures for common test data

**Location:**
- Ruby: `spec/factories/` (Rails convention)
- JavaScript: Inline mock data or `fixtures.js` in test directories
  - Example: `app/javascript/dashboard/composables/commands/spec/fixtures.js`

## Coverage

**Requirements:**
- Target coverage configured: lcov and text reporters
- HTML and SonarQube reports generated
- File: `coverage/sonar-report.xml`

**View Coverage:**
```bash
npm run test:coverage
# Coverage reports written to coverage/ directory
# View lcov-report/index.html in browser
```

**Exclusions from coverage:**
- `.spec.js` and `.test.js` files
- Story files (`.story.vue`, `.stories.js`)
- Route files (`*.routes.js`)
- i18n locale files (`i18n/**/*`)

## Test Types

**Unit Tests:**
- Scope: Individual functions, classes, components in isolation
- Approach: Mock external dependencies, test logic/behavior
- Examples: API client tests, action tests, component unit tests
- Location: Co-located with source or in `specs/` directory

**Integration Tests:**
- Scope: Multiple components/services working together
- Approach: Use real database (with transactions for isolation), mock external APIs
- Example patterns: `ContactIdentifyAction` tests that merge contacts and update attributes
- Location: Same as unit tests but test full workflows

**E2E Tests:**
- Framework: Not explicitly configured in vitest.config.ts
- Status: Not actively used in this codebase
- Note: Could be added with Cypress, Playwright, or similar

## Common Patterns

**Async Testing - JavaScript:**
```javascript
it('creates correct instance', () => {
  expect(accountAPI).toBeInstanceOf(ApiClient);
  expect(accountAPI).toHaveProperty('get');
});

it('#createAccount', async () => {
  const result = await accountAPI.createAccount({ name: 'Test' });
  expect(axiosMock.post).toHaveBeenCalledWith('/api/v1/accounts', { name: 'Test' });
});
```

**Async Testing - Ruby:**
```ruby
it 'enqueues avatar job when valid avatar url parameter is passed' do
  params = { name: 'test', avatar_url: 'https://chatwoot-assets.local/sample.png' }
  expect(Avatar::AvatarFromUrlJob).to receive(:perform_later).once
  described_class.new(contact: contact, params: params).perform
end
```

**Error Testing - JavaScript:**
```javascript
// Test error handling with specific error responses
it('handles validation error on account creation', () => {
  const axiosMock = {
    post: vi.fn(() => Promise.reject({ response: { status: 422 } })),
  };
  // Test that error message is shown
});
```

**Error Testing - Ruby:**
```ruby
it 'merges deeply nested additional attributes' do
  create(:contact, account: account,
         additional_attributes: { location: 'Bengaulru', social_profiles: { linkedin: 'saras' } })
  params = { email: 'test@test.com', additional_attributes: { social_profiles: { twitter: 'saras' } } }
  result = described_class.new(contact: contact, params: params).perform
  expect(result.additional_attributes['social_profiles']).to eq({ 'linkedin' => 'saras', 'twitter' => 'saras' })
end
```

## Test Helpers and Setup

**JavaScript Setup (`vitest.setup.js`):**
```javascript
import { config } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import i18nMessages from 'dashboard/i18n';
import FloatingVue from 'floating-vue';

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: i18nMessages,
});

config.global.plugins = [i18n, FloatingVue];
config.global.stubs = {
  WootModal: { template: '<div><slot/></div>' },
  WootModalHeader: { template: '<div><slot/></div>' },
  NextButton: { template: '<button><slot/></button>' },
};
```

**Global Test Environment:**
- i18n configured for all tests
- Vue plugins registered (Vue Test Utils config)
- Component stubs for common components to avoid rendering overhead
- IndexedDB polyfill: `fake-indexeddb/auto`

**Config Details:**
```javascript
test: {
  environment: 'jsdom',
  include: ['app/**/*.{test,spec}.?(c|m)[jt]s?(x)'],
  globals: true,  // Global test functions (describe, it, beforeEach, etc.)
  setupFiles: ['fake-indexeddb/auto', 'vitest.setup.js'],
  mockReset: true,  // Reset mocks between tests
  clearMocks: true,  // Clear mock calls between tests
}
```

## Test Count Summary

- **JavaScript/TypeScript specs:** 328 test files
- **Ruby spec files:** 601 test files
- **Total:** 929+ test files

---

*Testing analysis: 2026-02-11*
