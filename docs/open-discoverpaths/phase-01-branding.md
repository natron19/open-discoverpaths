# Phase 1 — Branding & Environment

**Goal:** Apply all boilerplate customization points — environment variables, accent color, custom CSS, and signed-in navbar links — so the app looks and feels like DiscoverPaths from the first run.

**Spec Sections:** 2 (Customizations), 8 (tightened settings), 12 (Bootstrap/CSS)  
**Guide References:** `CLAUDE.md` (ENV rules, no hardcoded names)

---

## Context at Start of Phase

The boilerplate is in place. Auth, admin panel, GeminiService, AiTemplate, LlmRequest, and the default home/dashboard pages all work. No domain models exist yet.

---

## Key Rules

- Every reference to the app name, tagline, or description must come from `ENV.fetch(...)`. Never hardcode these strings in views or layouts.
- Never write plain JavaScript. Navbar conditional visibility uses ERB `if current_user`, not JS.
- Dark mode only (`data-bs-theme="dark"` on `<html>`). Never add a theme toggle.

---

## Tasks

### Environment Variables

- [ ] **1.1** Update `.env.example` with these values (use placeholder-style comments, not real keys):
  ```
  APP_NAME=DiscoverPaths Demo
  APP_TAGLINE=Tell me about you. See several paths your life could actually take.
  APP_DESCRIPTION=An open source Rails 8 + Gemini demo that generates candidate life paths from your Personal Foundation.
  AI_CALLS_PER_USER_PER_DAY=15
  ```
  The `AI_CALLS_PER_USER_PER_DAY` cap is lowered to 15 (boilerplate default is 50) because path generation is consequential. See spec Section 8.

### Accent Color & CSS

- [ ] **1.2** Set accent color in `app/assets/stylesheets/application.css`:
  ```css
  :root {
    --accent: #65a30d;
    --accent-hover: #4d7c0f;
  }
  ```

- [ ] **1.3** Add horizontal card row scroll CSS to `application.css`:
  ```css
  .path-card-row {
    display: flex;
    gap: 1rem;
    overflow-x: auto;
    scroll-snap-type: x mandatory;
    padding-bottom: 1rem;
  }
  .path-card-row > .card {
    flex: 0 0 auto;
    scroll-snap-align: start;
    min-width: 320px;
    max-width: 380px;
  }
  ```

- [ ] **1.4** Add badge and card border custom CSS to `application.css`:
  ```css
  .badge-accent {
    background-color: var(--accent);
    color: #fff;
  }
  .card.exit-path {
    border: 2px solid var(--bs-secondary) !important;
  }
  .card.long-shot {
    border: 2px solid var(--accent) !important;
  }
  .disclaimer-card {
    color: var(--bs-secondary-color);
    font-size: 0.875rem;
  }
  ```

### Navbar

- [ ] **1.5** Add two signed-in-only nav links to `app/views/layouts/application.html.erb`, inside the existing nav collapse, visible only when `current_user` is set:
  ```erb
  <% if current_user %>
    <%= link_to "My Foundation", personal_foundation_path, class: "nav-link" %>
    <%= link_to "My Path Sets", path_sets_path, class: "nav-link" %>
  <% end %>
  ```
  Note: `personal_foundation_path` and `path_sets_path` routes don't exist yet — the links will raise a `NameError` until Phase 3 and Phase 4 add those routes. Add them now but be aware tests in later phases will verify them.

---

## RSpec Tests

No RSpec for this phase. There are no new models, controllers, or services to unit-test. ENV configuration and CSS are verified manually below.

---

## Manual Tests

Start the server (`bin/dev`) in a separate terminal before running these checks.

- [ ] Visit `/` — the navbar shows `DiscoverPaths Demo` (from `ENV.fetch("APP_NAME", ...)`), not a hardcoded string.
- [ ] Sign in as `demo@example.com` / `password123`.
- [ ] Confirm `My Foundation` and `My Path Sets` appear in the navbar after sign-in. (These links will 404 or raise until Phase 3/4 — that's expected at this stage; just confirm they render.)
- [ ] Inspect a primary button in the browser — confirm it uses the lime green (`#65a30d`) accent color.
- [ ] View page source — confirm no hardcoded "DiscoverPaths Demo" literal appears outside of ENV-driven output.

---

## Done When

- [ ] `.env.example` has all four app-specific variables
- [ ] Accent color variables are set in `application.css`
- [ ] Card row scroll and badge CSS is present
- [ ] Navbar shows foundation and path set links when signed in
- [ ] No hardcoded app name strings exist outside of ENV calls
