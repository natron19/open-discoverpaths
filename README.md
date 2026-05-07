# DiscoverPaths Demo

> Tell me about you. See several paths your life could actually take.

A Rails 8 + Gemini demo that takes a Personal Foundation and returns a Path Set
of 4 to 6 candidate life paths the user can hold side by side.

---

## Why I Built This

DiscoverPaths is a feature from the PATHS practice — a structured approach to thinking
about what comes next. The **A** in PATHS is Alternatives: instead of converging on one
answer, you hold several options next to each other long enough to see their real texture.

This demo is the Alternatives phase in isolation: a person fills out a Personal Foundation
(values, strengths, constraints, resources, current trajectory), and Gemini returns a Path
Set with milestones at year one, three, and ten, honest demands, real trade-offs, and profiles
of people already walking it. One path is flagged as the Exit Path (lower-stakes, more
recoverable), and one as the Long-Shot Path (higher risk, grounded in the person's resources).

DiscoverPaths offers paths. It does not pick one for you.

---

## App-Specific Setup

After running `bin/setup` (below):

1. Sign up at `/sign_up` or sign in with `demo@example.com` / `password123`
2. Fill in your Personal Foundation (`/personal_foundation/new`)
3. Click **Generate a New Path Set** on the dashboard
4. Browse cards, edit texture, and use the Compare Two view to place paths side by side

The Gemini prompt that drives generation lives at `/admin/ai_templates` — you can edit it
live without restarting the server.

---

## Quick Start

1. Clone this repo
2. Run `bin/setup`
3. Add your Gemini API key to `.env` (copy `.env.example` and fill in `GEMINI_API_KEY`)
4. `bin/dev`
5. Visit http://localhost:3000

Demo credentials: `demo@example.com` / `password123`

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_NAME` | `"DiscoverPaths Demo"` | Displayed in the navbar and title |
| `APP_TAGLINE` | — | Shown in the footer and hero |
| `APP_DESCRIPTION` | — | Meta description |
| `GEMINI_API_KEY` | (required) | Your Google Gemini API key — get one free at https://aistudio.google.com/app/apikey |
| `AI_CALLS_PER_USER_PER_DAY` | `50` | Daily AI call budget per user |
| `AI_GLOBAL_TIMEOUT_SECONDS` | `45` | Gemini request timeout in seconds (path generation can take 20–40s) |

---

## Editing the Prompt

The path generation template is stored in the database and editable at `/admin/ai_templates`.
Find `discoverpaths_pathset_v1` and click Edit. Changes take effect immediately — no restart
needed. The template uses `{{variable_name}}` syntax for interpolation.

Common things to tune:
- Number of paths (default: 4–6)
- Temperature (default: 0.8 — lower for more consistent output, higher for more variety)
- Milestone horizons
- The tone of the demands and trade-offs sections

---

## Stack

| Layer | Choice |
|---|---|
| Framework | Rails 8.1 |
| Database | PostgreSQL with UUID primary keys |
| Auth | Rails native (`has_secure_password`, sessions) |
| CSS | Bootstrap 5 dark mode (CDN) |
| JavaScript | Stimulus + Turbo via importmap |
| AI | Google Gemini via `gemini-ai` gem |
| Queue / Cache / Cable | Solid Stack (no Redis) |
| Testing | RSpec |

---

## AI Safety Posture

**What this app enforces:**
- Per-user daily call cap (default: 50/day, set via `AI_CALLS_PER_USER_PER_DAY`)
- Pre-flight gatekeeper: input length limit, prompt injection patterns, profanity filter
- Hard output token cap per template (3,000 tokens for path generation)
- Configurable request timeout (default: 45s for this app)
- Full request log with status, tokens, duration, and cost estimate (`/admin/llm_requests`)
- Fail-soft UI: errors render an inline alert, never crash the page
- AI disclaimer in the footer on every page
- Rate limiting on generation endpoints (10 requests per minute)

**Deliberately omitted:**
- No PII scrubbing — demo apps have no production user data
- No content moderation API — Gemini's built-in safety filters are sufficient
- No automatic retries — avoids stacking costs on transient failures
- No streaming — synchronous calls keep the code simple

---

## About the Author

Built by Nathan Rohm as part of the Open Demo Starter series — minimal Rails 8 + Gemini
demos that show one real feature, fully implemented, without boilerplate noise.

---

## License

MIT — see [LICENSE](LICENSE)
