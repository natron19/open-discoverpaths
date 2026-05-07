# Phase 8 — Landing Page & Final Cleanup

**Goal:** Replace the boilerplate home page with the DiscoverPaths pitch, update the README, audit every ENV reference, add rate limiting to path generation, and verify the disclaimer appears everywhere it should. After this phase, the demo is feature-complete and ready for the test suite and security check.

**Spec Sections:** 6 (home/index), 8 (disclaimer), 11 (README additions)  
**Guide References:** `CLAUDE.md` (ENV rule, no hardcoded strings), `docs/security.md` (rate limiting)

---

## Context at Start of Phase

- Phases 1–7 complete: all models, controllers, views, and Stimulus controllers are in place.
- The boilerplate home page (`home/index.html.erb`) still shows the default placeholder content.
- README may still have boilerplate placeholder text.
- No rate limiting has been added to `PathSetsController` yet.

---

## Key Rules

- Every string that names the app — `APP_NAME`, `APP_TAGLINE`, `APP_DESCRIPTION` — must come from `ENV.fetch(...)`. Grep the whole codebase before marking this done.
- Never hardcode "DiscoverPaths Demo" as a literal in any view or layout.
- Rate limiting uses Rails 8 native `rate_limit` — no Redis or Rack::Attack needed.
- Use `turbo_stream.update()` not `replace()` for any flash or dynamic content.

---

## Tasks

### Landing Page

- [ ] **8.1** Replace `app/views/home/index.html.erb` with the DiscoverPaths pitch:

  ```erb
  <div class="container py-5">

    <%# Hero %>
    <div class="row justify-content-center text-center mb-5">
      <div class="col-lg-8">
        <h1 class="display-5 fw-bold mb-3"><%= ENV.fetch("APP_NAME", "DiscoverPaths Demo") %></h1>
        <p class="lead text-muted mb-4"><%= ENV.fetch("APP_TAGLINE", "") %></p>
        <p class="mb-4">
          This demo takes a Personal Foundation — your values, strengths, constraints, resources,
          and current trajectory — and returns a Path Set of 4 to 6 candidate life paths you can
          hold side by side. Each path has concrete milestones, honest demands, real trade-offs,
          and profiles of people walking it. DiscoverPaths offers paths. It does not pick one for you.
        </p>
        <div class="d-flex gap-3 justify-content-center">
          <%= link_to "Get Started", sign_up_path, class: "btn btn-lg", style: "background-color: var(--accent); color: #fff;" %>
          <%= link_to "Sign In", sign_in_path, class: "btn btn-lg btn-outline-secondary" %>
        </div>
      </div>
    </div>

    <%# Offer-not-prescribe callout %>
    <div class="row justify-content-center mb-5">
      <div class="col-lg-7">
        <div class="card text-center">
          <div class="card-body py-4">
            <blockquote class="blockquote mb-0">
              <p>"<%= ENV.fetch("APP_NAME", "DiscoverPaths") %> offers paths. It does not prescribe one."</p>
            </blockquote>
            <p class="text-muted small mt-2 mb-0">Career quizzes hand you a job title. A blank ChatGPT prompt hands you confident but unspecific advice. The PATHS frame insists on several options held together — with honest texture — so you can do the choosing.</p>
          </div>
        </div>
      </div>
    </div>

    <%# Sample card preview (static mockup) %>
    <div class="row justify-content-center mb-5">
      <div class="col-12">
        <h4 class="text-center mb-3">What a path looks like</h4>
        <div class="path-card-row justify-content-center">

          <div class="card long-shot" style="min-width: 300px; max-width: 340px;">
            <div class="card-body">
              <span class="badge badge-accent mb-2">Long-Shot Path</span>
              <h5 class="card-title">Build a SaaS for design teams</h5>
              <p class="text-muted small">Turn a workflow problem into a small, sustainable product.</p>
              <h6 class="text-muted text-uppercase" style="font-size: 0.7rem;">Milestones</h6>
              <ul class="list-unstyled small mb-2">
                <li>Year 1: 10 paying customers</li>
                <li>Year 3: $5k MRR</li>
                <li>Year 10: Acquired or self-sustaining</li>
              </ul>
              <h6 class="text-muted text-uppercase" style="font-size: 0.7rem;">Trade-offs</h6>
              <ol class="small mb-0">
                <li>High failure rate</li>
                <li>Years before payoff</li>
                <li>Financial risk without a co-founder</li>
              </ol>
            </div>
          </div>

          <div class="card" style="min-width: 300px; max-width: 340px;">
            <div class="card-body">
              <h5 class="card-title">Independent Consultant</h5>
              <p class="text-muted small">Run a one-person design consulting practice serving 3–5 clients at a time.</p>
              <h6 class="text-muted text-uppercase" style="font-size: 0.7rem;">Milestones</h6>
              <ul class="list-unstyled small mb-2">
                <li>Year 1: First two retainer clients</li>
                <li>Year 3: $120k revenue</li>
                <li>Year 10: Established practice with a waiting list</li>
              </ul>
              <h6 class="text-muted text-uppercase" style="font-size: 0.7rem;">Trade-offs</h6>
              <ol class="small mb-0">
                <li>No employer benefits</li>
                <li>Slower career signal than a senior title</li>
                <li>Isolation without deliberate community</li>
              </ol>
            </div>
          </div>

          <div class="card exit-path" style="min-width: 300px; max-width: 340px;">
            <div class="card-body">
              <span class="badge bg-secondary mb-2">Exit Path</span>
              <h5 class="card-title">Return to Stable Employment</h5>
              <p class="text-muted small">Take a well-scoped senior IC role at a larger company.</p>
              <h6 class="text-muted text-uppercase" style="font-size: 0.7rem;">Milestones</h6>
              <ul class="list-unstyled small mb-2">
                <li>Year 1: Role secured with good scope</li>
                <li>Year 3: One promotion</li>
                <li>Year 10: Staff or principal title</li>
              </ul>
              <h6 class="text-muted text-uppercase" style="font-size: 0.7rem;">Trade-offs</h6>
              <ol class="small mb-0">
                <li>Less autonomy</li>
                <li>Newsletter stays a hobby</li>
                <li>Slower wealth building</li>
              </ol>
            </div>
          </div>

        </div>
      </div>
    </div>

    <%# Sign-up CTA (repeated at bottom) %>
    <div class="text-center">
      <p class="text-muted mb-3">Sign up and write your own foundation. Generate your first Path Set in under five minutes.</p>
      <%= link_to "Start for Free", sign_up_path, class: "btn btn-lg", style: "background-color: var(--accent); color: #fff;" %>
    </div>

  </div>
  ```

### ENV Audit

- [ ] **8.2** Grep the entire codebase for hardcoded app name strings:
  ```
  grep -r "DiscoverPaths Demo" app/ config/ db/ --include="*.erb" --include="*.rb" --include="*.yml"
  ```
  Any hit outside of `db/seeds.rb` (where it's a legitimate seed value) must be replaced with `ENV.fetch("APP_NAME", "DiscoverPaths Demo")`.

- [ ] **8.3** Confirm `APP_TAGLINE` and `APP_DESCRIPTION` in views come from ENV, not hardcoded strings.

### README

- [ ] **8.4** Update `README.md` — add or update these sections (see spec Section 11 for full text):

  **Header:**
  ```markdown
  # DiscoverPaths Demo

  > Tell me about you. See several paths your life could actually take.

  A Rails 8 + Gemini demo that takes a Personal Foundation and returns a Path Set
  of 4 to 6 candidate life paths the user can hold side by side.
  ```

  **Why I Built This** — explain this is one feature from the DiscoverPaths SaaS, the Alternatives phase of the PATHS practice.

  **Editing the Prompt** — explain that the template lives in `/admin/ai_templates` and can be edited live.

  **App-Specific Setup** — the four steps a new visitor takes after `bin/setup`.

  Preserve all standard boilerplate sections (Stack, Setup, License, AI Safety Posture, About the Author).

### Disclaimer Audit

- [ ] **8.5** Confirm the disclaimer card (from spec Section 8) appears on `path_sets/show.html.erb`. The exact text:
  > *These paths are starting points for your own thinking. They are generated from what you wrote in your foundation, which means they reflect what you told the system about yourself, not what is true about you. Sit with each path. Talk to people walking it. Edit the texture as you learn what you actually believe. DiscoverPaths offers paths; it does not pick one for you.*

  Also confirm the boilerplate's footer AI disclaimer is present in `app/views/layouts/application.html.erb`.

### Rate Limiting

- [ ] **8.6** Add Rails 8 native rate limiting to `PathSetsController`. After the `before_action :load_path_set` line:
  ```ruby
  rate_limit to: 10, within: 1.minute, only: [:create, :regenerate],
             with: -> { render partial: "shared/ai_error", locals: { error_type: :error } }
  ```
  This prevents excessive generation even within the daily budget cap.

---

## RSpec Tests

No new model or request specs needed in this phase. The changes are views, README, and rate limiting configuration. Verify the full suite still passes:

- [ ] Run: `bundle exec rspec` — confirm zero failures after landing page and cleanup changes.

---

## Manual Tests

Start the server (`bin/dev`) before running.

- [ ] Visit `/` signed out — landing page shows the demo description and three sample cards.
- [ ] Confirm app name in the navbar reads from ENV (not hardcoded).
- [ ] Click "Get Started" CTA — navigated to the sign-up form.
- [ ] Full end-to-end demo run as a fresh user:
  1. Sign up with a new email
  2. Fill in the Personal Foundation form
  3. Click "Generate a new Path Set" on the dashboard
  4. Review all cards — check all texture fields render
  5. Click Edit on one card — inline edit works
  6. Click "Compare Two" — compare selector appears
  7. Select two paths and click Compare — compare view renders
  8. Click Regenerate — new paths replace old ones
- [ ] Visit `/admin/llm_requests` — each generation step shows status `success`.
- [ ] Disclaimer card appears at the bottom of every PathSet show page.
- [ ] Footer AI disclaimer is visible in the layout.

---

## Done When

- [ ] Landing page replaced with DiscoverPaths pitch and static sample cards
- [ ] No hardcoded `APP_NAME` / `APP_TAGLINE` / `APP_DESCRIPTION` strings in views
- [ ] README updated with all sections from spec Section 11
- [ ] Disclaimer text present on PathSet show page
- [ ] Rate limiting on `create` and `regenerate` actions
- [ ] `bundle exec rspec` passes with zero failures
