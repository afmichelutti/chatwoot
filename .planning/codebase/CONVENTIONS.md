# Coding Conventions

**Analysis Date:** 2026-02-11

## Naming Patterns

**Files:**
- Vue components: PascalCase (e.g., `AccordionItem.vue`, `AddAccountModal.vue`)
- JavaScript files: camelCase (e.g., `account.js`, `ApiClient.js`, `useBulkActions.js`)
- Ruby files: snake_case (e.g., `contact_identify_action.rb`, `contact_merge_action.rb`)
- Test files: `.spec.js` for JavaScript, `_spec.rb` for Ruby

**Functions/Methods:**
- JavaScript: camelCase (e.g., `createAccount`, `getCacheKeys`, `addAccount`)
- Ruby: snake_case (e.g., `merge_if_existing_identified_contact`, `process_contact_merge`)
- Vue methods: camelCase (e.g., `addAccount`, `onToggle`)

**Variables:**
- JavaScript: camelCase (e.g., `accountName`, `accountId`, `axiosMock`)
- Ruby: snake_case (e.g., `account_name`, `custom_attributes`, `phone_number`)
- Component props: camelCase in JavaScript, kebab-case in templates (e.g., `isOpen`, `icon`, `emoji`)

**Types/Classes:**
- Vue components (in template): PascalCase (e.g., `<AccordionItem />`, `<NextButton />`)
- JavaScript classes: PascalCase (e.g., `ApiClient`, `AccountAPI`)
- Ruby classes: PascalCase (e.g., `ContactIdentifyAction`, `ContactMergeAction`)

## Code Style

**Formatting:**
- Tool: Prettier
- Print width: 80 characters
- Quotes: Single quotes
- Trailing commas: es5 (objects/arrays, not function arguments)
- Arrow function parameters: No parentheses when single parameter (avoid: `(a) =>`, use: `a =>`)

**Linting:**
- Tool: ESLint
- Base config: airbnb-base/legacy with Vue3 recommended
- Plugin: vue (for Vue 3), vitest-globals (for test globals), @intlify/vue-i18n
- Key rules enforced:
  - `prettier/prettier`: Error - Prettier formatting is enforced
  - `no-console`: Error - Console logging forbidden (except in stories)
  - `camelcase`: Off - Allows snake_case from backend APIs
  - `import/no-extraneous-dependencies`: Off
  - `import/prefer-default-export`: Off

**Vue-specific rules:**
- Component definitions must use PascalCase: `<PascalCase />`
- Props using `defineProps` with runtime declaration required
- Emits using `defineEmits` with explicit declaration required
- Block order: `<script>`, `<template>`, `<style>`
- Custom event names: camelCase
- Macro variable names required: `props`, `emit`, `slots`
- Max attributes per line: 20 on single line, 1 on multiline
- Self-closing elements required (both HTML and components)
- No bare strings in templates (must be i18n keys or allowlisted symbols)
- Define components with composition API (`<script setup>`) for new code

## Import Organization

**Order:**
1. Vue/library imports (`vue`, `@vuelidate/validators`)
2. Framework imports (`@sentry/vue`, `floating-vue`)
3. Path alias imports (`dashboard`, `shared`, `components`)
4. Relative imports (`./components`, `../utils`)

**Path Aliases:**
- `components`: `app/javascript/dashboard/components`
- `next`: `app/javascript/dashboard/components-next`
- `v3`: `app/javascript/v3`
- `dashboard`: `app/javascript/dashboard`
- `helpers`: `app/javascript/shared/helpers`
- `shared`: `app/javascript/shared`
- `survey`: `app/javascript/survey`
- `widget`: `app/javascript/widget`
- `assets`: `app/javascript/dashboard/assets`

## Error Handling

**Patterns:**
- JavaScript: Try-catch blocks with user alerts
  - Example: `useAlert()` composable for UI notifications
  - Error responses checked for status codes (e.g., 422 for validation)
- Ruby: Exception handling with transaction rollback
  - Example: `ActiveRecord::Base.transaction` wraps critical operations
  - Return `@contact` after successful perform
  - Call `save!` to raise exceptions on failures

## Logging

**Framework:** console (disabled in production code)

**Patterns:**
- No console logging in production code (rule: `no-console: error`)
- Story files can use console for debugging (rule override)
- Comments preferred for developer notes (TODO/FIXME)

## Comments

**When to Comment:**
- Mark architectural decisions with comments
- Use TODO/FIXME for technical debt (e.g., "TODO: replace with compact_blank when rails upgraded")
- Explain "why" for non-obvious logic, not "what" the code does
- No JSDoc required for simple getters/setters

**Common Comments Found:**
- `// TODO: [description]` - Future improvements
- `// FIXME: [description]` - Known issues to fix
- `# TODO: [description]` - Ruby equivalent

## Function Design

**Size:** Keep functions focused and reasonably short

**Parameters:**
- JavaScript: Use destructuring for options/config objects
  - Example: `new ApiClient(resource, options = {})`
  - Use `pattr_initialize` in Ruby for parameter initialization
- Prefer keyword arguments in Ruby

**Return Values:**
- JavaScript: Return promises from async operations
- Ruby: Return the primary object being modified (e.g., `return @contact`)
- Explicit return statements used consistently

## Module Design

**Exports:**
- JavaScript classes: `export default new ClassName()` (singleton pattern)
- JavaScript utilities: Named exports preferred for reusable functions
- Ruby: Classes instantiated with action pattern (e.g., `described_class.new(...).perform`)

**Barrel Files:** Not heavily used; imports are direct from source files

**Vue Components:**
- Single file components with `.vue` extension
- Setup format (`<script setup>`) for newer components
- Options API (data, computed, methods) still used in legacy components
- Composition API preferred: `<script setup>` with `defineProps`, `defineEmits`

## Backend (Ruby) Conventions

**Service Classes:**
- Named with `*Action` or `*Service` suffix
- Use `pattr_initialize` for dependency injection
- `perform` method as public entry point
- Private methods for implementation details
- Use composition over inheritance

**Models:**
- Validations at model level
- Scopes for common queries
- `deep_merge` for nested attribute updates
- `transaction` blocks for multi-step operations

**Controllers:**
- Standard REST action names
- Request/response handled by serializers
- Error handling with HTTP status codes

---

*Convention analysis: 2026-02-11*
