# DiscoverPaths Demo - Spec Document

**Document Version:** 1.0
**Last Updated:** May 4, 2026
**Built On:** Open Demo Starter v2.0
**Source PRD:** 11_DiscoverPaths_PRD_v2.md (production spec)
**Accent Color:** `#65a30d` (forest lime)
**License:** MIT

---

## 1. App Overview

DiscoverPaths Demo is a Rails 8 single-feature open source app that takes a Personal Foundation from a signed-in user and returns a Path Set of 4 to 6 candidate life paths. Each Path includes a name, a one-line positioning, three Milestones (year 1, 3, 10), three honest Demands, three Trade-offs, and three Real People profiles. One Path is flagged as the Exit Path and one as the Long-Shot Path.

This demo isolates the single most valuable thing the production DiscoverPaths SaaS does: it generates concrete, comparable life paths from a person's own values, strengths, constraints, and resources, then lets the person hold them side by side. Career quizzes ask "what should I do?" and answer with a job title. The PATHS framework asks "which paths are real for me right now?" and answers with several options the person can keep, reject, or edit. This demo is the path generator at the core of that practice.

The production DiscoverPaths is a multi-tenant SaaS supporting families, coaching engagements, workshop cohorts, and community programs across the full PATHS practice (Personal foundation, Alternatives, Trials, Helpers, Shifts) over years and life stages. The full app supports trials, helper relationships, shifts, monthly reviews, and longitudinal timelines. This open source demo is scoped down to a single signed-in user generating and comparing paths from a single foundation; it ships nothing else from the larger framework.

This demo is open source under the MIT license and runs on localhost. The full production app is available at `https://discoverpaths.app` (placeholder).

---

## 2. Customizations Applied to the Boilerplate

This list is the complete set of places this demo diverges from Open Demo Starter v2.0 defaults.

- **Branding.** `APP_NAME=DiscoverPaths Demo`, `APP_TAGLINE=Tell me about you. See several paths your life could actually take.`, `APP_DESCRIPTION` set in `.env.example`.
- **Accent color.** `#65a30d` (forest lime) and a hover tone of `#4d7c0f` set in `app/assets/stylesheets/_accent.scss`.
- **Navbar.** Adds two links visible only when signed in: `My Foundation` and `My Path Sets`. No marketing nav.
- **Home page.** `home/index.html.erb` replaced with the demo's landing pitch: a one-paragraph description, a sample path card preview, the "offer not prescribe" framing statement, and a sign-up call to action.
- **Dashboard page.** `dashboard/show.html.erb` replaced with two stacked sections: the user's Personal Foundation summary (or a "Start your foundation" empty state) and a list of Path Sets they have generated (most recent first).
- **UX pattern.** Personal foundation form (left side, vertical) plus path comparison cards (right side, horizontal scroll). On the Path Set show page, the cards are the dominant UI element.
- **Daily call cap.** Lowered from the boilerplate default of 50 to **15** via `AI_CALLS_PER_USER_PER_DAY=15` in `.env.example`. Rationale in Section 8.
- **AI template seeded.** `discoverpaths_pathset_v1` added to `db/seeds.rb`. Full content in Section 7.

Everything else is unchanged from the boilerplate.

---

## 3. Data Model

Three new domain models on top of `User`, `AiTemplate`, and `LlmRequest`.

### PersonalFoundation

The user's inputs about themselves. One per user (the demo restricts users to one active foundation; editing replaces it).

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `user_id` | uuid | Foreign key. **(template variable, indirectly via the assembled prompt)** |
| `values` | text | 3 to 5 values, each with a one-sentence why. **(template variable: `{{values}}`)** |
| `strengths` | text | 3 strengths with specific evidence. **(template variable: `{{strengths}}`)** |
| `constraints` | text | 2 to 3 honest constraints (financial, geographic, family, health). **(template variable: `{{constraints}}`)** |
| `resources` | text | 3 to 5 resources (skills, networks, capital, credentials). **(template variable: `{{resources}}`)** |
| `current_trajectory` | text | One sentence: what would happen if the user kept doing what they are doing. **(template variable: `{{current_trajectory}}`)** |
| `created_at` | datetime | |
| `updated_at` | datetime | |

Associations:
- `belongs_to :user`
- `has_many :path_sets, dependent: :destroy`

Validations:
- `values`, `strengths`, `constraints`, `resources`, `current_trajectory` all required, each at least 20 characters.
- A user can have at most one PersonalFoundation (uniqueness on `user_id`).

### PathSet

A single generation event that produces 4 to 6 LifePath records.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `personal_foundation_id` | uuid | Foreign key |
| `user_id` | uuid | Denormalized for fast scoping |
| `generated_at` | datetime | When the Gemini call returned successfully |
| `gemini_raw` | text | Full Gemini response. **(Gemini output, used for Show raw response toggle)** |
| `created_at` | datetime | |
| `updated_at` | datetime | |

Associations:
- `belongs_to :personal_foundation`
- `belongs_to :user`
- `has_many :life_paths, dependent: :destroy`

Validations:
- `personal_foundation_id` required.
- `user_id` required.

### LifePath

One Path inside a Path Set. Created by the Gemini parser; texture fields are editable by the user after generation.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | |
| `path_set_id` | uuid | Foreign key |
| `name` | string | The path's short name (e.g., "Independent design consultancy") |
| `positioning` | string | One-line description |
| `milestones` | text | Year 1, year 3, year 10 markers, stored as a structured text block |
| `demands` | text | Three things this path requires |
| `trade_offs` | text | Three honest costs |
| `real_people` | text | Three general profiles of people walking this path (no specific named individuals) |
| `is_exit_path` | boolean | At most one true per Path Set |
| `is_long_shot` | boolean | At most one true per Path Set |
| `position` | integer | Display order in the card row |
| `created_at` | datetime | |
| `updated_at` | datetime | |

Associations:
- `belongs_to :path_set`

Validations:
- `name`, `positioning`, `milestones`, `demands`, `trade_offs`, `real_people` all required.
- A Path Set can have at most one path with `is_exit_path: true` and at most one with `is_long_shot: true`.

---

## 4. Routes

| Verb | Path | Controller#Action | Purpose |
|---|---|---|---|
| GET | `/dashboard` | `dashboard#show` | Foundation summary plus list of Path Sets |
| GET | `/personal_foundation/new` | `personal_foundations#new` | First-time foundation form |
| POST | `/personal_foundation` | `personal_foundations#create` | Save the foundation |
| GET | `/personal_foundation` | `personal_foundations#show` | View current foundation |
| GET | `/personal_foundation/edit` | `personal_foundations#edit` | Edit foundation |
| PATCH | `/personal_foundation` | `personal_foundations#update` | Update foundation |
| POST | `/path_sets` | `path_sets#create` | Generate a new Path Set (triggers Gemini) |
| GET | `/path_sets/:id` | `path_sets#show` | Card row view of all paths |
| POST | `/path_sets/:id/regenerate` | `path_sets#regenerate` | Regenerate from current foundation (triggers Gemini, replaces paths) |
| GET | `/path_sets/:id/compare` | `path_sets#compare` | Side-by-side two-column view (`?path_a=ID&path_b=ID`) |
| PATCH | `/life_paths/:id` | `life_paths#update` | Manual edit of texture on one path (no AI call) |

The `personal_foundation` resource is singular because each user has at most one. All HTML responses; no JSON API. Auth and admin routes inherited from the boilerplate.

---

## 5. Controllers and Actions

### `DashboardController`

Overrides the boilerplate placeholder.

- `show`: Loads `current_user.personal_foundation` (may be nil) and `current_user.path_sets.order(generated_at: :desc).limit(10)`. Renders the dashboard template.

### `PersonalFoundationsController`

- `new`: Renders the foundation form. Redirects to `show` if a foundation already exists.
- `create`: Builds a foundation from strong params, scoped to `current_user`. On success, redirects to `dashboard#show` with a flash. On failure, re-renders the form.
- `show`: Renders the user's current foundation in read mode. 404 if none exists.
- `edit`: Renders the form pre-populated.
- `update`: Updates the foundation. Existing PathSets remain; the user must regenerate or create a new one to see updated paths.

### `PathSetsController`

- `create`: Looks up `current_user.personal_foundation` (404 if missing). Calls `GeminiService.generate(template: "discoverpaths_pathset_v1", variables: {...})`. Parses the JSON response; creates a `PathSet` record and 4 to 6 `LifePath` children inside a transaction. Stores the raw response on `gemini_raw`. On `GeminiService::GeminiError`, renders the boilerplate's `shared/_gemini_error` partial inline with a retry button.
- `show`: Loads the PathSet scoped to `current_user`, eager-loads `life_paths` ordered by `position`. Renders the horizontal card row.
- `regenerate`: Same as `create` but operates on an existing PathSet. Wraps in a transaction: destroys old `life_paths`, calls Gemini, parses the response, creates new `life_paths`, updates `gemini_raw` and `generated_at`. On error, the existing paths are preserved (transaction rollback).
- `compare`: Loads two `LifePath` records (by `path_a` and `path_b` query params), both scoped through the PathSet's user. Renders a two-column comparison view.

### `LifePathsController`

- `update`: Updates one of `name`, `positioning`, `milestones`, `demands`, `trade_offs`, `real_people` on a single `LifePath` scoped through `current_user.path_sets`. Renders a Turbo Stream replace of the affected card. Does NOT call Gemini; this is manual texture editing only.

All controllers inherit from `ApplicationController` (already requires authentication), scope queries to `current_user`, use strong parameters, and rescue `GeminiService::GeminiError` per the boilerplate convention.

---

## 6. Views

### `home/index.html.erb` (replaces boilerplate placeholder)

Landing pitch. One-paragraph description, a sample card preview (static HTML, no live data), a callout block stating "DiscoverPaths offers paths. It does not prescribe one.", and a sign-up button.

### `dashboard/show.html.erb` (replaces boilerplate placeholder)

Two stacked sections.
- **Foundation summary card.** If `personal_foundation` exists: read-only summary of the five fields with an Edit link. If not: a prominent "Start your foundation" call to action that links to `personal_foundations#new`.
- **Path Sets list.** A vertical list (not a grid) of recent Path Sets with `generated_at` timestamp, count of paths, a link to view, and a "Generate a new Path Set" primary button at the top (disabled if no foundation exists).

### `personal_foundations/_form.html.erb`

Single-column form with five labeled `textarea` fields for `values`, `strengths`, `constraints`, `resources`, `current_trajectory`. Each field has helper text describing what the user should enter. Submit button color uses `var(--accent)`.

### `personal_foundations/new.html.erb` and `edit.html.erb`

Both render `_form.html.erb` with the appropriate URL and submit text.

### `personal_foundations/show.html.erb`

Read-only rendering of the five fields with the Edit button.

### `path_sets/show.html.erb`

The primary visual pattern of this demo.

- Header: "Path Set generated `<relative time>`. Based on your foundation as of `<foundation update time>`." with a "Regenerate" button (primary color) that POSTs to `path_sets#regenerate`.
- Below header: a Bootstrap toggle group that switches between "Card row" and "Compare two".
- **Card row view (default).** A horizontally scrollable container of fixed-width cards (`min-width: 320px` each). Each card renders the path's full texture: name, positioning, three Milestones, three Demands, three Trade-offs, three Real People. A small "Edit" icon on each card opens a Turbo Frame inline editor.
- **Card borders.** Default cards: `border: 1px solid var(--bs-border-color)`. Exit Path: `border: 2px solid var(--bs-secondary)` plus a small "Exit Path" badge. Long-Shot Path: `border: 2px solid var(--accent)` plus a "Long-Shot Path" badge.
- **Compare two view.** A small selector for Path A and Path B (each a dropdown of the paths in this set). Once both selected, navigates to `path_sets#compare`. Renders two columns side by side at full card width.
- Bottom of page: a "Show raw response" Bootstrap collapse that reveals `gemini_raw` content in a `<pre>` block. This is required for every Gemini-output view per the boilerplate convention.
- Bottom of page below raw toggle: an inline disclaimer card with the "offer not prescribe" framing language. See Section 8.

### `path_sets/compare.html.erb`

Two-column Bootstrap row, each column a single `_path_card.html.erb` partial rendered at full width. Header above explains "Comparing `<Path A name>` and `<Path B name>`. Switch one at a time to feel the trade-offs honestly." Has a "Back to all paths" link.

### `path_sets/_path_card.html.erb` (partial)

The shared card markup used by both the row view and the compare view. Accepts a `life_path` local. Renders all fields. Wraps in a Turbo Frame keyed by `life_path_<id>` so the inline editor can replace just one card.

### `life_paths/_edit_form.html.erb` (partial)

Inline form rendered inside the Turbo Frame on a card when the user clicks Edit. Six textarea fields (one per editable text field). Submits via Turbo to `life_paths#update`, which replaces the frame with the updated card.

### `shared/_gemini_error.html.erb`

Provided by the boilerplate. Used as-is.

### Stimulus controllers

- `path_compare_controller`: Manages the two dropdowns and enables the "Compare" link only when both selections are valid and different.
- `card_scroller_controller`: Optional, adds left/right arrow buttons that scroll the horizontal card row by one card width.

No other custom JavaScript.

---

## 7. AI Templates and Gemini Integration

This demo seeds **one** AI template. The full record content below is what `db/seeds.rb` creates; the template is editable in `/admin/ai_templates` after seeding.

### Template: `discoverpaths_pathset_v1`

**`description`:** Generates 4 to 6 candidate life paths from a Personal Foundation. Returns JSON. Strict offer-not-prescribe framing.

**`system_prompt`:**

```
You are an exploratory thinking partner inside DiscoverPaths, a tool that helps a person hold several possible paths for their life next to each other.

You are NOT a recommender. You do not rank paths. You do not produce a "best path" or a "recommended path." You produce options.

You will receive a Personal Foundation describing a real person's values, strengths, constraints, resources, and current trajectory. Your job is to return between 4 and 6 candidate life Paths that this specific person could realistically explore. Each Path must be grounded in the foundation provided. Do not generate paths that ignore the person's stated constraints. Do not invent constraints they did not state.

Each Path must include:
1. name: a short, concrete name for this path (not a job title alone; the texture of the life)
2. positioning: one sentence describing what this path is, in the person's terms
3. milestones: an object with year_1, year_3, year_10 keys, each a one-sentence concrete marker of what success on this path looks like at that horizon
4. demands: a list of exactly three things this path will ask of the person, written honestly (not aspirationally)
5. trade_offs: a list of exactly three honest costs of this path, including what the person will not get if they walk it
6. real_people: a list of exactly three general profiles of people who walk this path. Do NOT name specific public individuals. Use general descriptions like "a former teacher who runs a one-person consulting practice in a small city" not "Jane Doe."
7. is_exit_path: boolean. Set true on exactly one Path that represents a reasonable fallback if the person's current path becomes impossible. The Exit Path should be lower-stakes and more recoverable.
8. is_long_shot: boolean. Set true on exactly one Path that represents what the person might pursue if they allowed themselves to want it. The Long-Shot Path should require more risk than the others, and should still be grounded in their resources.

Style:
- Plain language. No hedging clauses like "you might consider." State each path concretely.
- Honest about cost. A Path with no trade-offs is a fantasy, not a path.
- Specific. Avoid generic advice that would apply to anyone.
- One Path must be is_exit_path. One Path must be is_long_shot. The other 2 to 4 are neither.

You will return only valid JSON in the schema below. No prose before or after.
```

**`user_prompt_template`:**

```
Personal Foundation:

VALUES:
{{values}}

STRENGTHS:
{{strengths}}

CONSTRAINTS:
{{constraints}}

RESOURCES:
{{resources}}

CURRENT TRAJECTORY:
{{current_trajectory}}

Return JSON in this exact shape:

{
  "paths": [
    {
      "name": "string",
      "positioning": "string",
      "milestones": {
        "year_1": "string",
        "year_3": "string",
        "year_10": "string"
      },
      "demands": ["string", "string", "string"],
      "trade_offs": ["string", "string", "string"],
      "real_people": ["string", "string", "string"],
      "is_exit_path": boolean,
      "is_long_shot": boolean
    }
  ]
}

Return between 4 and 6 paths. Exactly one path must have is_exit_path: true. Exactly one path must have is_long_shot: true.
```

**Variables consumed:**
- `{{values}}` from `PersonalFoundation#values`
- `{{strengths}}` from `PersonalFoundation#strengths`
- `{{constraints}}` from `PersonalFoundation#constraints`
- `{{resources}}` from `PersonalFoundation#resources`
- `{{current_trajectory}}` from `PersonalFoundation#current_trajectory`

**`model`:** `gemini-2.0-flash` (boilerplate default; suitable for structured JSON output)

**`max_output_tokens`:** `3000` (raised from the boilerplate default of 2000 because a 6-path JSON response with full texture for each is consistently around 1800 to 2400 tokens; 3000 leaves headroom).

**`temperature`:** `0.8` (raised from the boilerplate default of 0.7 because path variety is the point; lower temperatures collapse the paths toward a similar profile).

**`notes`:**

```
Watch for these failure modes when iterating on this template:

1. The model occasionally produces paths that are too similar to each other. If this happens, increase temperature or add an explicit instruction that "the 4 to 6 paths must differ from each other along at least two dimensions: location, income trajectory, social setting, daily structure, or risk profile."

2. The model occasionally invents constraints the user did not state. The system prompt addresses this; if it persists, add a sentence reinforcing it.

3. The model occasionally tries to rank or recommend a path despite the system prompt. Watch the gemini_raw output for words like "recommended," "best," "should choose." If they appear, strengthen the offer-not-prescribe instruction.

4. The model sometimes names specific real public figures in real_people. The system prompt forbids this. If it persists, add a sentence: "Real people examples must be general profiles. Do not name any individual, public or private."

5. JSON parse failures should be rare with gemini-2.0-flash but are possible. The controller wraps the parse in begin/rescue and treats parse failure as a Gemini error.
```

**Where it's called.** `PathSetsController#create` and `PathSetsController#regenerate`.

**Expected output format.** JSON. The schema is defined in the user prompt above. The controller parses with `JSON.parse(result)`, then iterates `paths` and creates one `LifePath` per item. The `gemini_raw` field on `PathSet` stores the unparsed response string for the "Show raw response" toggle.

**Parsing notes.** The parser must validate that exactly one path has `is_exit_path: true` and exactly one has `is_long_shot: true`. If the model violates this, the controller logs a warning, picks the first true value for each flag, and clears the rest. This is a soft fix; the raw response is still preserved.

This demo does not use Gemini's function calling. A single synchronous call generates the full Path Set.

---

## 8. AI Safety Considerations (Specific to This App)

DiscoverPaths is a **higher-stakes** demo than most in the portfolio. The user is asking an LLM about their life. The output describes paths the user might take seriously enough to act on. The risk surface is broad: a poorly worded path could push a vulnerable user toward a decision they later regret; a path that ignores stated constraints could waste months of the user's time; a real_people example that names a specific person could embarrass that person.

### Content Sensitivity

This app touches:
- **Career and life decisions.** Direct downstream consequences for the user.
- **Financial constraints.** A user disclosing a financial constraint expects the app not to produce a path that ignores it.
- **Family and health constraints.** Users may disclose caregiving responsibilities or health conditions in their constraints field. The model must treat these as real and non-negotiable.
- **Identity considerations.** Paths can implicate values, religious community, partnership status, and life stage.

### Consequential Outputs

A user could act on a Path Set in ways that change their life: leaving a job, moving cities, starting graduate school, leaving a relationship to pursue a path. The worst case is not catastrophic in the safety-critical sense (this is not medical or legal advice) but it is consequential. The user could spend significant time and money following a path that the model produced from a 30-second prompt.

### App-Specific Mitigations Beyond the Boilerplate

1. **Offer-not-prescribe framing in the system prompt.** The system prompt forbids ranking, recommending, or producing a "best path." The model is instructed to generate options, not advice.

2. **Persistent disclaimer on every Path Set view.** Below the Show Raw Response toggle, a card with the following text in muted styling:

   > *These paths are starting points for your own thinking. They are generated from what you wrote in your foundation, which means they reflect what you told the system about yourself, not what is true about you. Sit with each path. Talk to people walking it. Edit the texture as you learn what you actually believe. DiscoverPaths offers paths; it does not pick one for you.*

3. **Lower per-user daily call cap.** `AI_CALLS_PER_USER_PER_DAY=15` instead of the boilerplate default of 50. A user does not need 50 path generations a day; if they are generating that many, they are not using the tool the way it is designed. The cap is a friction signal.

4. **Editable paths.** Every path is user-editable after generation. The user can rewrite the texture as they learn. This embeds the "you are the author" principle in the UI itself.

5. **Real-people instruction in the prompt.** Specific named individuals are forbidden in `real_people`. The notes field on the template flags this as a watch item.

### What This Demo Deliberately Does NOT Do

- **No therapy framing.** The app does not ask "how are you feeling?" and does not respond to expressions of distress with anything other than the standard Gemini error handling. Users in crisis should see a human, not a path generator. The README states this.
- **No crisis intervention triggers.** A production app of this nature might add suicide-and-self-harm content detection. This demo does not, because demo-scale inputs do not justify the complexity, but the README flags it as a production-only concern.
- **No prediction of outcomes.** The model never says "this path will likely succeed" or assigns probabilities. Paths are options; outcomes are unknown.
- **No comparison ranking.** The "Compare two paths" view places paths side by side without scoring or recommending. Visual symmetry is intentional.
- **No goal-setting nudge.** The app does not push the user to "pick one." The user can hold the Path Set indefinitely.
- **No saved chat history with Gemini.** Each generation is a single shot. There is no follow-up conversation, no "tell me more about path 3," no agent loop.
- **No PII scrubbing on inputs.** The user is told in the README not to paste real personal data they do not want logged. Demo apps do not run a Presidio-like layer; the production app does.

### Tightened Settings Summary

- `AI_CALLS_PER_USER_PER_DAY`: 15 (was 50)
- `max_output_tokens`: 3000 (was 2000; raised because the schema requires it; not a safety concern)
- `temperature`: 0.8 (was 0.7; raised for path variety)
- All other boilerplate guardrails (gatekeeper, timeout, request logging, raw response toggle, fail-soft UI, footer disclaimer) apply unchanged.

This is a substantive safety section because the app deserves one. An interviewer reading the spec sees explicit risk thinking baked into the design.

---

## 9. RSpec Outline

New spec files for this demo. Each lists 3 to 5 specific tests.

### `spec/models/personal_foundation_spec.rb`
- Validates presence of all five text fields.
- Validates uniqueness of `user_id` (one foundation per user).
- `belongs_to :user` and `has_many :path_sets`.
- Destroying a foundation destroys its path sets.

### `spec/models/path_set_spec.rb`
- `belongs_to :personal_foundation` and `belongs_to :user`.
- Validates presence of `personal_foundation_id` and `user_id`.
- `has_many :life_paths` with `dependent: :destroy`.
- A scope or finder confirms a different user's PathSet is not retrievable through `current_user.path_sets`.

### `spec/models/life_path_spec.rb`
- Validates presence of `name`, `positioning`, `milestones`, `demands`, `trade_offs`, `real_people`.
- A path set may have at most one `is_exit_path: true` and one `is_long_shot: true` (custom validation).
- `belongs_to :path_set`.

### `spec/requests/personal_foundations_spec.rb`
- `GET /personal_foundation/new` renders for a signed-in user with no existing foundation.
- `POST /personal_foundation` creates a foundation scoped to `current_user`.
- A signed-in user cannot view another user's foundation (404 on a foreign id).
- `PATCH /personal_foundation` updates only the current user's foundation.

### `spec/requests/path_sets_spec.rb`
- `POST /path_sets` calls the Gemini test double and creates a PathSet plus 4 to 6 LifePath children.
- The `LlmRequest` record is created with status `success` after the call (verifies boilerplate logging integration).
- `POST /path_sets/:id/regenerate` destroys old paths and creates new ones in a transaction.
- `GET /path_sets/:id/compare` requires both `path_a` and `path_b` query params and validates they belong to the same set.
- Access control: a different signed-in user receives 404 when requesting another user's PathSet.

### `spec/requests/life_paths_spec.rb`
- `PATCH /life_paths/:id` updates one path's texture without calling Gemini.
- Verifies no `LlmRequest` is created on edit.
- Access control: a different signed-in user cannot update another user's LifePath.

The boilerplate's specs (`user_spec.rb`, `ai_template_spec.rb`, `llm_request_spec.rb`, `gemini_service_spec.rb`, `ai_gatekeeper_spec.rb`, `ai_budget_checker_spec.rb`, and the auth request specs) are not redescribed here.

The Gemini test double from the boilerplate stubs `GeminiService.generate(template: "discoverpaths_pathset_v1", variables: anything)` to return a fixed valid JSON string with five sample paths, one flagged as exit, one as long-shot.

---

## 10. Seed Data

`db/seeds.rb` extends the boilerplate's seeded admin user (`demo@example.com` / `password123`).

### AiTemplate Seed

One record with the full content from Section 7. The seed uses `find_or_create_by(name: "discoverpaths_pathset_v1")` so re-seeding does not duplicate.

```ruby
AiTemplate.find_or_create_by!(name: "discoverpaths_pathset_v1") do |t|
  t.description = "Generates 4 to 6 candidate life paths from a Personal Foundation. Returns JSON. Strict offer-not-prescribe framing."
  t.system_prompt = "<full system prompt from Section 7>"
  t.user_prompt_template = "<full user prompt template from Section 7>"
  t.model = "gemini-2.0-flash"
  t.max_output_tokens = 3000
  t.temperature = 0.8
  t.notes = "<full notes from Section 7>"
end
```

### Domain Seed

A sample `PersonalFoundation` for the seeded admin user, with realistic content so a visitor can immediately click "Generate Path Set" and see the demo work.

```ruby
admin = User.find_by!(email: "demo@example.com")

admin.create_personal_foundation!(
  values: "Autonomy: I want to control my own time. Craft: I care about doing things well, not fast. Family: my partner and I want to keep weekends free. Honesty: I do not want to sell things I do not believe in. Curiosity: I read across fields and want a job that rewards that.",
  strengths: "Writing: I have published a newsletter for three years with 4,000 subscribers. Systems thinking: at my last role I redesigned an onboarding process that cut new-hire ramp from 90 days to 45. Teaching: I have run weekend workshops for early-career designers since 2022 and consistently get high feedback.",
  constraints: "Financial: I need at least $90k a year to stay in our current city without family support. Geographic: my partner's job anchors us to one of three U.S. metros for the next four years. Family: we are planning to have a child within two years and I want to be present for the early years.",
  resources: "Skills: writing, design systems, public speaking, light Ruby and SQL. Networks: 60-ish design leaders I know personally from a community I co-run. Capital: about 14 months of runway in savings. Credentials: a portfolio, a small audience, a few notable past employers. Time: about 8 hours of side-project capacity per week.",
  current_trajectory: "If I keep doing what I am doing, I will stay in my current senior design role for another two years, get one promotion, and continue running the newsletter and workshops on the side without ever testing whether either could be the main thing."
)
```

The seed does NOT pre-create a Path Set. The visitor generates one themselves on first run, which is the actual demo experience. (A pre-created PathSet would skip the most interesting part.)

---

## 11. README Additions

The boilerplate's README template provides the standard sections (Stack, Setup, License, AI Safety Posture, About the Author). This demo's README extends it with:

### Header

```markdown
# DiscoverPaths Demo

> Tell me about you. See several paths your life could actually take.

A Rails 8 + Gemini demo that takes a Personal Foundation and returns a Path Set
of 4 to 6 candidate life paths the user can hold side by side.

[Screenshot placeholder: dashboard view showing a Path Set with five cards in
a horizontal row, the Long-Shot path bordered in forest lime, the Exit path
bordered in muted gray.]
```

### Why I Built This

```markdown
## Why I Built This

This is one feature from DiscoverPaths, a multi-tenant SaaS I am building for
life and career exploration. The full product runs the five-phase PATHS
practice (Personal foundation, Alternatives, Trials, Helpers, Shifts) for
individuals, families, coaching engagements, and workshop cohorts. Production
landing page: https://discoverpaths.app (placeholder).

This demo isolates the Alternatives phase: the path generator. It is the first
output a new DiscoverPaths user sees, and it is the part most people get wrong
when they try to do this themselves with a generic LLM. Career quizzes hand
you a job title. A blank prompt to ChatGPT hands you confident but unspecific
advice. The PATHS frame insists on several paths held together with honest
texture (milestones, demands, trade-offs, real people), and on the offer-not-
prescribe principle that the AI does not pick for you.

I open sourced this so visitors can read the prompt, edit it in the admin UI,
fork the repo, and see how I think about safety considerations on a higher-
stakes AI feature. The full SaaS is closed source under a separate license.

MIT licensed. Use it, fork it, learn from it.
```

### Editing the Prompt

```markdown
## Editing the Prompt

The path generation prompt is stored as an `AiTemplate` record, not in the
codebase. Sign in as the seeded admin user (`demo@example.com` / `password123`)
and visit `/admin/ai_templates/discoverpaths_pathset_v1/edit` to read it,
edit it, and test it live against the Gemini API. Save persists changes
without restarting the server.
```

### App-Specific Setup Notes

```markdown
## App-Specific Setup

After running `bin/setup`:

1. Sign in as `demo@example.com` / `password123`.
2. The seeded user already has a sample Personal Foundation. Click
   "Generate Path Set" on the dashboard to see the demo work end to end.
3. To see the offer-not-prescribe framing in the prompt, visit
   `/admin/ai_templates`.
4. To see your Gemini calls being logged, visit `/admin/llm_requests`.

This demo lowers `AI_CALLS_PER_USER_PER_DAY` to 15 (boilerplate default is 50)
because path generation is consequential and the cap is a friction signal.
You can change this in `.env`.
```

The standard "Stack", "Setup", "License", "AI Safety Posture", and "About the Author" sections come from the boilerplate template unchanged. The boilerplate's footer note ("AI-generated content can be incorrect. Verify before acting.") applies; this demo's per-page disclaimer (Section 8) is in addition to it.

---

## 12. Bootstrap Dark Mode and Accent Color Notes

The Open Demo Starter ships Bootstrap 5 in dark mode with `data-bs-theme="dark"` on `<html>`. This demo applies the following:

### Accent Color Application

Set in `app/assets/stylesheets/_accent.scss`:

```scss
:root {
  --accent: #65a30d;
  --accent-hover: #4d7c0f;
}
```

The accent color is used on:
- Primary submit buttons (`btn-primary` overridden via custom CSS to use `var(--accent)`)
- The active navbar link state
- The Long-Shot Path card border (`border: 2px solid var(--accent)`)
- The "Long-Shot Path" badge background
- The active state of the "Card row vs. Compare two" Bootstrap toggle group
- Inline links within prose

### UX Pattern Choice

The demo is **form-then-result**: the foundation form on one page, the path cards on another. There is no kanban, no wizard, no calendar. This pattern matches the demo's narrow scope.

### Card Styling

The Path Set show page uses Bootstrap `card` components with custom width and border treatment:
- Default card: `border: 1px solid var(--bs-border-color)`, `min-width: 320px`, `max-width: 380px`.
- Exit Path card: `border: 2px solid var(--bs-secondary)` plus a "Exit Path" badge using `bg-secondary`.
- Long-Shot Path card: `border: 2px solid var(--accent)` plus a "Long-Shot Path" badge using a custom accent background.
- Card body: tight vertical rhythm (`py-2` between sections), section headings in muted color.

### Horizontal Scrolling Container

The card row uses Bootstrap utilities plus minimal custom CSS:

```scss
.path-card-row {
  display: flex;
  gap: 1rem;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  padding-bottom: 1rem; // room for the scrollbar
}

.path-card-row > .card {
  flex: 0 0 auto;
  scroll-snap-align: start;
}
```

### Compare View

Two columns at full width using Bootstrap's `row` with two `col-md-6`. On mobile, columns stack vertically. The two cards inside use the same `_path_card.html.erb` partial as the row view.

### Form Styling

The Personal Foundation form uses Bootstrap's standard `form-control` textareas with a vertical, single-column layout. Helper text under each field uses `form-text` with `text-muted`. Labels are `form-label` weight 500. The submit button is full width on mobile, auto width on desktop, and uses the accent color.

### Custom CSS Footprint

Beyond `_accent.scss` and the card row scroll utilities above, this demo adds about 30 lines of custom CSS for the badge backgrounds, the helper text spacing, and the disclaimer card styling. Everything else uses Bootstrap utilities.

---

*v1.0 - DiscoverPaths Demo spec. Built on Open Demo Starter v2.0. Open source under MIT license.*
