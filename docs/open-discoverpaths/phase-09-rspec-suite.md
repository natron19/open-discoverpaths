# Phase 9 — Full RSpec Suite Verification

**Goal:** Run the complete test suite, confirm zero failures and zero real Gemini API calls, close any spec gaps identified during development, and review the output for coverage completeness.

**Spec Sections:** 9 (RSpec Outline)  
**Guide References:** `docs/testing.md` (patterns and helpers), `CLAUDE.md` (never run RSpec automatically — share output for review)

---

## Context at Start of Phase

All phases (1–8) are complete. Specs written incrementally during each phase should already exist:

| Spec file | Written in |
|---|---|
| `spec/models/personal_foundation_spec.rb` | Phase 2 |
| `spec/models/path_set_spec.rb` | Phase 2 |
| `spec/models/life_path_spec.rb` | Phase 2 |
| `spec/requests/personal_foundations_spec.rb` | Phase 3 |
| `spec/requests/path_sets_spec.rb` | Phase 4 (extended in Phase 5) |
| `spec/requests/life_paths_spec.rb` | Phase 6 |

---

## Key Rules

- **Never make real Gemini API calls in tests.** All specs must stub `GeminiService.generate`. Confirm no spec file is missing the stub.
- Use `gemini_returns(text)` and `gemini_raises(error_class)` helpers from `spec/support/gemini_test_double.rb`.
- Use the `sign_in_as(user)` helper from `spec/support/authentication_helpers.rb`.
- Access control tests must use 404 (not 403) for admin routes and cross-user resource access.

---

## Tasks

### Verify Gemini Stub Fixture

- [ ] **9.1** Confirm `SAMPLE_PATHSET_JSON` constant exists (added in Phase 4) in `spec/support/gemini_test_double.rb` or a shared fixture. It must be a valid JSON string with 5 paths: one `is_exit_path: true`, one `is_long_shot: true`, three standard.

### Verify Existing Model Specs

- [ ] **9.2** Run model specs and confirm all pass:
  ```
  bundle exec rspec spec/models/personal_foundation_spec.rb spec/models/path_set_spec.rb spec/models/life_path_spec.rb
  ```
  If any fail, fix before proceeding.

### Verify Existing Request Specs

- [ ] **9.3** Run request specs and confirm all pass:
  ```
  bundle exec rspec spec/requests/personal_foundations_spec.rb spec/requests/path_sets_spec.rb spec/requests/life_paths_spec.rb
  ```
  If any fail, fix before proceeding.

### Gap Analysis — Additional Tests to Add

Review the spec Section 9 outline against what exists. Add any missing tests:

- [ ] **9.4** `spec/requests/personal_foundations_spec.rb` — verify all five checks:
  - [ ] `GET /personal_foundation/new` → 200 when no foundation exists
  - [ ] `GET /personal_foundation/new` → redirect to show when foundation already exists
  - [ ] `POST /personal_foundation` → creates foundation scoped to `current_user`
  - [ ] `PATCH /personal_foundation` → updates only the current user's record
  - [ ] Unauthenticated access to all routes → redirect to sign in

- [ ] **9.5** `spec/requests/path_sets_spec.rb` — verify all six checks:
  - [ ] `POST /path_sets` → creates PathSet + 4–6 LifePath children (stubbed Gemini)
  - [ ] `POST /path_sets` → on Gemini error → renders ai_error partial
  - [ ] `POST /path_sets` → creates `LlmRequest` with status `success`
  - [ ] `POST /path_sets/:id/regenerate` → destroys old LifePaths, creates new ones
  - [ ] `GET /path_sets/:id` → 200 for owner, 404 for another user
  - [ ] `GET /path_sets/:id/compare` → requires both params; 404 if paths are from wrong set

- [ ] **9.6** `spec/requests/life_paths_spec.rb` — verify all four checks:
  - [ ] `PATCH /life_paths/:id` → updates texture without calling Gemini
  - [ ] `PATCH /life_paths/:id` → no `LlmRequest` created
  - [ ] `PATCH /life_paths/:id` → 404 for a different signed-in user
  - [ ] Unauthenticated access → redirect to sign in

### Boilerplate Spec Check

- [ ] **9.7** Run the boilerplate's existing specs to confirm nothing was broken:
  ```
  bundle exec rspec spec/models/user_spec.rb spec/models/ai_template_spec.rb spec/models/llm_request_spec.rb
  ```
  ```
  bundle exec rspec spec/requests/sessions_spec.rb spec/requests/registrations_spec.rb
  ```

### Full Suite

- [ ] **9.8** Run the complete test suite:
  ```
  bundle exec rspec
  ```
  **Required outcome:** Zero failures. Zero pending examples that represent missing coverage (pending on work-in-progress is acceptable if noted).

- [ ] **9.9** Run with documentation format and review the output:
  ```
  bundle exec rspec --format documentation
  ```
  Read through the output. Check for:
  - Missing auth checks (unauthenticated access to any protected route)
  - Missing cross-user access checks
  - Any `GeminiService.generate` that is not stubbed (would cause a real API call)

- [ ] **9.10** Confirm zero real Gemini API calls were made during the test run by checking that `LlmRequest` records created in tests all use stubbed data (status `success` with the fixture JSON, not actual Gemini output).

---

## RSpec Tests

This phase is the test phase — all tests listed above are the deliverable.

---

## Manual Tests

- [ ] Run `bundle exec rspec` and share the output. All examples must pass.
- [ ] Run `bundle exec rspec --format documentation` and scan for obvious gaps.
- [ ] Confirm `AI_CALLS_PER_USER_PER_DAY` is not used by any test (tests must not depend on budget behavior unless specifically testing the budget checker).

---

## Done When

- [ ] `bundle exec rspec` passes with zero failures
- [ ] No real Gemini API calls in the test suite
- [ ] All six spec files exist and are complete per the gap analysis
- [ ] Documentation format output reviewed for coverage completeness
