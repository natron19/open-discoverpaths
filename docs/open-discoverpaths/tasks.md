# DiscoverPaths Demo — Build Task Tracker

Built on: Open Demo Starter v2.0  
Spec: `docs/open-discoverpaths/discoverpaths_demo_spec.md`  
Accent: `#65a30d` (forest lime)  
Last updated: 2026-05-06

---

## How to Use This File

Work through phases in order. Each phase has its own document with implementation tasks, RSpec tests, and manual checks. Complete and verify all tests before advancing.

> **Model note:** The spec (Section 7) lists `gemini-2.0-flash` but that model returns 404 on new API keys. Use `gemini-2.5-flash` everywhere.

---

## Phases

| # | Phase | File | Status |
|---|---|---|---|
| 1 | Branding & Environment | [phase-01-branding.md](phase-01-branding.md) | `[x]` |
| 2 | Data Models & Migrations | [phase-02-models.md](phase-02-models.md) | `[x]` |
| 3 | Personal Foundation CRUD | [phase-03-foundation-crud.md](phase-03-foundation-crud.md) | `[x]` |
| 4 | AI Template & Path Generation | [phase-04-ai-integration.md](phase-04-ai-integration.md) | `[x]` |
| 5 | Path Display Views & Compare | [phase-05-path-display.md](phase-05-path-display.md) | `[x]` |
| 6 | Inline LifePath Editing | [phase-06-inline-editing.md](phase-06-inline-editing.md) | `[x]` |
| 7 | Stimulus Controllers | [phase-07-stimulus.md](phase-07-stimulus.md) | `[x]` |
| 8 | Landing Page & Final Cleanup | [phase-08-landing-cleanup.md](phase-08-landing-cleanup.md) | `[x]` |
| 9 | Full RSpec Suite Verification | [phase-09-rspec-suite.md](phase-09-rspec-suite.md) | `[ ]` |
| 10 | Security Check & Publish | [phase-10-security-publish.md](phase-10-security-publish.md) | `[x]` |

---

## Final Completion Checklist

Run this before declaring the demo done.

- [ ] `.env.example` committed with all required variables, no real keys
- [ ] `config/master.key` is gitignored (never committed)
- [ ] `bundle exec rspec` passes with zero failures and zero real Gemini API calls
- [ ] `rails db:seed` runs cleanly from a fresh database
- [ ] Demo run as `demo@example.com` / `password123` works end-to-end
- [ ] Admin panel (`/admin/ai_templates`, `/admin/llm_requests`) functions correctly
- [ ] Health check (`GET /up/llm`) returns `{ status: "ok" }` with valid `GEMINI_API_KEY`
- [ ] No `binding.pry`, `debugger`, or hardcoded credentials in the codebase
- [ ] No `turbo_stream.replace()` calls — all use `update()`
- [ ] No plain JavaScript (`onclick`, `addEventListener`, `<script>` tags) — all Stimulus
- [ ] App name / tagline / description all read from `ENV.fetch`
- [ ] Disclaimer card appears on every PathSet show page
- [ ] README reflects the actual setup experience
- [ ] Pre-publish security check from `docs/prompts/pre-publish-security-check.md` completed

---

*Spec source: `docs/open-discoverpaths/discoverpaths_demo_spec.md` v1.0*
