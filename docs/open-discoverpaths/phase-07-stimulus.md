# Phase 7 — Stimulus Controllers

**Goal:** Wire up two Stimulus controllers — `path_compare_controller` (enables the Compare link only when two different paths are selected) and an optional `card_scroller_controller` (left/right arrow scroll for the card row).

**Spec Sections:** 6 (Stimulus controllers)  
**Guide References:** `docs/turbo-stimulus-patterns.md` (Stimulus patterns, importmap registration)

---

## Context at Start of Phase

- Phase 5 added the compare selector HTML to `path_sets/show.html.erb` with `data-controller="path-compare"` and Stimulus target attributes already in place.
- Phase 5's view currently uses inline `onclick` as a placeholder for the Card Row / Compare Two toggle — this phase replaces those with proper Stimulus.
- Stimulus controllers live in `app/javascript/controllers/`. They are auto-registered via `app/javascript/controllers/index.js` (importmap).
- CSP is active — inline `onclick` in the view is a temporary placeholder that may be blocked. This phase resolves it.

---

## Key Rules

- **Stimulus only.** No vanilla JS, no `addEventListener`, no `document.querySelector`.
- Register controllers in `app/javascript/controllers/index.js` using `import` + `application.register(...)`.
- Use `data-controller`, `data-action`, and `data-*-target` attributes. Never manipulate the DOM outside of a Stimulus controller method.
- Pass configuration to controllers via Stimulus Values API (`data-controller-name-value`), not hard-coded in JS.

---

## Tasks

### View Toggle Controller (Card Row ↔ Compare Two)

The Phase 5 placeholder used inline `onclick`. Replace with a proper controller.

- [ ] **7.1** Create `app/javascript/controllers/panel_toggle_controller.js`:

  ```js
  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    static targets = ["panel", "button"]
    static values  = { active: { type: Number, default: 0 } }

    connect() {
      this.showPanel(this.activeValue)
    }

    show(event) {
      const index = this.buttonTargets.indexOf(event.currentTarget)
      this.showPanel(index)
    }

    showPanel(activeIndex) {
      this.panelTargets.forEach((panel, i) => {
        panel.classList.toggle("d-none", i !== activeIndex)
      })
      this.buttonTargets.forEach((btn, i) => {
        btn.classList.toggle("active", i === activeIndex)
      })
    }
  }
  ```

- [ ] **7.2** Register in `app/javascript/controllers/index.js`:
  ```js
  import PanelToggleController from "./panel_toggle_controller"
  application.register("panel-toggle", PanelToggleController)
  ```

- [ ] **7.3** Update the toggle button group in `app/views/path_sets/show.html.erb` — replace inline `onclick` with Stimulus wiring:

  ```erb
  <div class="btn-group mb-4" role="group"
       data-controller="panel-toggle"
       data-panel-toggle-active-value="0">
    <button type="button" class="btn btn-outline-secondary active"
            data-panel-toggle-target="button"
            data-action="click->panel-toggle#show">
      Card Row
    </button>
    <button type="button" class="btn btn-outline-secondary"
            data-panel-toggle-target="button"
            data-action="click->panel-toggle#show">
      Compare Two
    </button>
  </div>

  <div id="card-row-view" data-panel-toggle-target="panel">
    ...card row content...
  </div>

  <div id="compare-view" class="d-none" data-panel-toggle-target="panel"
       data-controller="path-compare"
       data-path-compare-base-url-value="<%= compare_path_set_path(@path_set) %>">
    ...compare selector content...
  </div>
  ```

### Path Compare Controller

- [ ] **7.4** Create `app/javascript/controllers/path_compare_controller.js`:

  ```js
  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    static targets = ["path_a_select", "path_b_select", "compare_link"]
    static values  = { baseUrl: String }

    connect() {
      this.update()
    }

    update() {
      const a = this.path_a_selectTarget.value
      const b = this.path_b_selectTarget.value
      const valid = a && b && a !== b

      this.compare_linkTarget.classList.toggle("disabled", !valid)
      if (valid) {
        this.compare_linkTarget.href = `${this.baseUrlValue}?path_a=${a}&path_b=${b}`
      }
    }
  }
  ```

- [ ] **7.5** Register in `app/javascript/controllers/index.js`:
  ```js
  import PathCompareController from "./path_compare_controller"
  application.register("path-compare", PathCompareController)
  ```

  The compare selector HTML in `path_sets/show.html.erb` already has the correct `data-controller`, `data-action`, and `data-path-compare-target` attributes from Phase 5. No view changes needed.

### Card Scroller Controller (Optional)

- [ ] **7.6** _(Optional)_ Create `app/javascript/controllers/card_scroller_controller.js`:

  ```js
  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    static targets = ["container", "left_button", "right_button"]

    connect() {
      this.updateButtons()
      this.containerTarget.addEventListener("scroll", () => this.updateButtons())
    }

    scrollLeft()  { this.containerTarget.scrollBy({ left: -340, behavior: "smooth" }) }
    scrollRight() { this.containerTarget.scrollBy({ left:  340, behavior: "smooth" }) }

    updateButtons() {
      const el   = this.containerTarget
      const atStart = el.scrollLeft <= 0
      const atEnd   = el.scrollLeft + el.clientWidth >= el.scrollWidth - 1
      if (this.hasLeft_buttonTarget)  this.left_buttonTarget.classList.toggle("invisible", atStart)
      if (this.hasRight_buttonTarget) this.right_buttonTarget.classList.toggle("invisible", atEnd)
    }
  }
  ```

- [ ] **7.7** _(Optional)_ Register in `app/javascript/controllers/index.js`:
  ```js
  import CardScrollerController from "./card_scroller_controller"
  application.register("card-scroller", CardScrollerController)
  ```

- [ ] **7.8** _(Optional)_ Wrap the `.path-card-row` in `path_sets/show.html.erb` with the scroller controller:
  ```erb
  <div data-controller="card-scroller" class="position-relative">
    <button class="btn btn-sm btn-outline-secondary position-absolute start-0 top-50 translate-middle-y invisible"
            data-card-scroller-target="left_button"
            data-action="click->card-scroller#scrollLeft">&larr;</button>
    <div class="path-card-row" data-card-scroller-target="container">
      ...cards...
    </div>
    <button class="btn btn-sm btn-outline-secondary position-absolute end-0 top-50 translate-middle-y"
            data-card-scroller-target="right_button"
            data-action="click->card-scroller#scrollRight">&rarr;</button>
  </div>
  ```

---

## RSpec Tests

No RSpec for this phase. Stimulus controllers are JavaScript and run in the browser. Browser behavior is verified through manual tests below.

If you want to add JavaScript unit tests, use Jest or a similar framework — but this boilerplate does not include a JS test runner by default.

---

## Manual Tests

Start the server (`bin/dev`) before running.

- [ ] On a PathSet show page, click "Compare Two" toggle button — the compare selector section appears; card row hides.
- [ ] Click "Card Row" toggle button — card row appears; compare selector hides.
- [ ] In the compare selector: leave both dropdowns unselected — Compare button is disabled.
- [ ] Select the same path for Path A and Path B — Compare button remains disabled.
- [ ] Select two different paths — Compare button becomes enabled with a correct URL.
- [ ] Click Compare — navigates to the two-column compare view.
- [ ] Browser console — no JavaScript errors.
- [ ] _(If card scroller implemented)_ Left arrow is hidden at scroll start; right arrow is visible.
- [ ] _(If card scroller implemented)_ Click right arrow — cards scroll smoothly.
- [ ] _(If card scroller implemented)_ Scroll to the end — right arrow hides, left arrow appears.

---

## Done When

- [ ] `panel_toggle_controller.js` registered and handles Card Row / Compare Two toggle
- [ ] No inline `onclick` in `path_sets/show.html.erb`
- [ ] `path_compare_controller.js` registered and enables/disables Compare link correctly
- [ ] Compare link URL is correct when two different paths are selected
- [ ] No JavaScript console errors on any path set page
