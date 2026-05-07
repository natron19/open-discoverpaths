# Phase 10 — Security Check & Publish

**Goal:** Run the pre-publish security review, resolve every finding, verify the final completion checklist, and prepare the repo for public GitHub publication.

**Security Check Prompt:** `docs/prompts/pre-publish-security-check.md`  
**Guide References:** `docs/security.md` (CSP, headers, secrets), `CLAUDE.md` (gitignore rules, no PII in logs)

---

## Context at Start of Phase

All phases (1–9) are complete. The demo is feature-complete and all RSpec specs pass. This phase is purely about safety before making the repo public.

---

## Key Rules

- Never commit `.env` or `config/master.key`.
- `.env.example` must contain only placeholder values — no real API keys, tokens, or passwords.
- `db/seeds.rb` may contain demo credentials (`demo@example.com` / `password123`) only because they are documented in the README as intentional demo values.
- Git history must not contain any commit that ever had a real secret. If `git log` shows suspicious commit messages, the history must be scrubbed before publishing.
- The demo app ships no internal URLs, real email addresses, or server names in the README.

---

## Tasks

### Run the Pre-Publish Security Check

- [ ] **10.1** Open `docs/prompts/pre-publish-security-check.md` and run the full prompt against this codebase. The prompt checks ten items:

  1. **Hardcoded secrets** — scan all files for API keys, passwords, tokens in `.env`, `config/`, initializers, and `.kamal/`.
  2. **Gitignore coverage** — confirm `.env`, `master.key`, `*.key`, `config/credentials.yml.enc`, `log/`, and `tmp/` are all covered.
  3. **`.env.example`** — every value must be a placeholder, not a real value.
  4. **`config/database.yml`** — production values must use `ENV.fetch(...)`, no hardcoded credentials.
  5. **`db/seeds.rb`** — only intentional demo credentials (documented in README); no real secrets.
  6. **`config/environments/production.rb`** — all sensitive values must use `ENV.fetch(...)`.
  7. **`Gemfile`** — only `https://rubygems.org` as gem source; no private servers or private git sources.
  8. **README** — no internal infrastructure details, internal URLs, real email addresses beyond `demo@example.com`, or team names.
  9. **Log and tmp files** — `log/` and `tmp/` must contain no tracked files with sensitive content.
  10. **Git history** — `git log --oneline` reviewed for commit messages suggesting a secret was ever committed.

- [ ] **10.2** For each finding flagged by the security check:
  - If fixable directly (e.g., update `.gitignore`, change a placeholder value) — fix it.
  - If it requires rotating a key — note it for the operator; don't rotate in the codebase.
  - If git history contains a committed secret — squash or rebase before publishing (this is a manual step; document the finding and ask the user to decide before pushing).

### Final Completion Checklist

Verify every item before marking the project done:

- [ ] `.env.example` committed with all required variables, no real keys
- [ ] `config/master.key` is in `.gitignore` and not committed
- [ ] `bundle exec rspec` passes with zero failures and zero real Gemini API calls
- [ ] `rails db:seed` runs cleanly from a fresh database (`rails db:drop db:create db:migrate db:seed`)
- [ ] Demo run as `demo@example.com` / `password123` works end-to-end:
  - Dashboard loads with foundation summary
  - Generate a Path Set → 4–6 cards appear
  - Edit a path card inline → card updates without page reload
  - Compare two paths → two-column view renders
  - Regenerate → new paths replace old ones
- [ ] Admin panel functions: `/admin/ai_templates`, `/admin/llm_requests`
- [ ] Health check: `GET /up/llm` returns `{ status: "ok" }` with a valid `GEMINI_API_KEY`
- [ ] No `binding.pry`, `debugger`, or hardcoded credentials anywhere in the codebase
- [ ] No `turbo_stream.replace()` calls — grep confirms all use `update()`
- [ ] No plain JavaScript — grep confirms no `onclick=`, `addEventListener(`, or `<script>` tags in views
- [ ] All app name / tagline / description strings read from `ENV.fetch`
- [ ] Disclaimer card present on every PathSet show page
- [ ] README is accurate and reflects the actual setup experience
- [ ] Pre-publish security check: all ten items resolved

### Grep Checks (Run These)

```bash
# No turbo_stream.replace in views or controllers
grep -r "turbo_stream\.replace" app/ --include="*.rb" --include="*.erb"

# No plain JS onclick in views
grep -r "onclick=" app/views/ --include="*.erb"

# No addEventListener in views
grep -r "addEventListener" app/views/ --include="*.erb"

# No hardcoded app name (outside seeds)
grep -r "DiscoverPaths Demo" app/ --include="*.erb" --include="*.rb"

# No binding.pry or debugger
grep -r "binding\.pry\|debugger" app/ spec/

# Confirm master.key is not tracked
git ls-files config/master.key

# Confirm .env is not tracked
git ls-files .env
```

Each of these commands should return no output. If any returns output, fix the issue before publishing.

---

## RSpec Tests

No new specs in this phase. Confirm `bundle exec rspec` still passes after any fixes applied during the security check.

---

## Manual Tests

- [ ] Reset to a fresh database and reseed:
  ```
  rails db:drop db:create db:migrate db:seed
  ```
  Confirm no errors.
- [ ] Sign in as `demo@example.com` / `password123` — dashboard loads with the seeded foundation.
- [ ] Click "Generate a new Path Set" — confirm the Gemini call succeeds and paths appear.
- [ ] Run all grep checks listed above — confirm zero hits.
- [ ] Review `.gitignore` — confirm all sensitive files are covered.
- [ ] Review the most recent `git log --oneline` entries — no suspicious messages.

---

## Done When

- [ ] All ten items in the pre-publish security check are resolved
- [ ] All grep checks return empty output
- [ ] `bundle exec rspec` passes
- [ ] Fresh database seed works
- [ ] End-to-end demo works as `demo@example.com`
- [ ] Repo is ready to push to a public GitHub remote
