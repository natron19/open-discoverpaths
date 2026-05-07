# Phase 5 — Path Display Views & Compare

**Goal:** Complete the full path card UI — horizontally scrollable card row with all texture fields, Exit/Long-Shot badge treatment, the `_path_card` shared partial, and the two-column compare view. After this phase, the PathSet show page is visually complete.

**Spec Sections:** 6 (Views — path_sets/show, compare, _path_card), 12 (Bootstrap/CSS details)  
**Guide References:** `docs/turbo-stimulus-patterns.md` (Turbo Frame on cards)

---

## Context at Start of Phase

- Phase 4 complete: PathSetsController generates paths, basic show page renders card names/positioning only.
- CSS for `.path-card-row`, `.exit-path`, `.long-shot`, `.badge-accent` is already in `application.css` (Phase 1).
- No `_path_card.html.erb` partial exists yet. The inline edit form (Phase 6) will slot into the Turbo Frame this phase sets up.

---

## Key Rules

- Wrap each card in `turbo_frame_tag "life_path_#{life_path.id}"` — this is required for Phase 6's inline edit to work. Do it now.
- Never use `turbo_stream.replace()` — use `update()`. (Phase 6 will use this pattern.)
- No plain JavaScript. The compare selector toggle is a Stimulus responsibility (Phase 7). This phase adds the HTML structure; Stimulus wires it up later.
- Milestone, demands, trade-offs, and real-people fields are stored as multi-line text (newline-delimited). Render with `simple_format` or split and display as list items.

---

## Tasks

### Shared Path Card Partial

- [ ] **5.1** Create `app/views/path_sets/_path_card.html.erb`:

  ```erb
  <%= turbo_frame_tag "life_path_#{life_path.id}" do %>
    <div class="card h-100 <%= 'exit-path' if life_path.is_exit_path? %> <%= 'long-shot' if life_path.is_long_shot? %>">
      <div class="card-body">

        <%# Type badge %>
        <% if life_path.is_exit_path? %>
          <span class="badge bg-secondary mb-2">Exit Path</span>
        <% elsif life_path.is_long_shot? %>
          <span class="badge badge-accent mb-2">Long-Shot Path</span>
        <% end %>

        <%# Header + edit link %>
        <div class="d-flex justify-content-between align-items-start mb-2">
          <h5 class="card-title mb-0"><%= life_path.name %></h5>
          <%= link_to "Edit", edit_life_path_path(life_path),
                data: { turbo_frame: "life_path_#{life_path.id}" },
                class: "btn btn-sm btn-outline-secondary py-0 px-2" %>
        </div>

        <p class="text-muted small mb-3"><%= life_path.positioning %></p>

        <%# Milestones %>
        <h6 class="text-muted text-uppercase" style="font-size: 0.7rem; letter-spacing: 0.05em;">Milestones</h6>
        <ul class="list-unstyled small mb-3">
          <% life_path.milestones.split("\n").each do |m| %>
            <li><%= m %></li>
          <% end %>
        </ul>

        <%# Demands %>
        <h6 class="text-muted text-uppercase" style="font-size: 0.7rem; letter-spacing: 0.05em;">Demands</h6>
        <ol class="small mb-3">
          <% life_path.demands.split("\n").each do |d| %>
            <li><%= d %></li>
          <% end %>
        </ol>

        <%# Trade-offs %>
        <h6 class="text-muted text-uppercase" style="font-size: 0.7rem; letter-spacing: 0.05em;">Trade-offs</h6>
        <ol class="small mb-3">
          <% life_path.trade_offs.split("\n").each do |t| %>
            <li><%= t %></li>
          <% end %>
        </ol>

        <%# Real People %>
        <h6 class="text-muted text-uppercase" style="font-size: 0.7rem; letter-spacing: 0.05em;">Real People</h6>
        <ul class="list-unstyled small mb-0">
          <% life_path.real_people.split("\n").each do |p| %>
            <li class="mb-1">— <%= p %></li>
          <% end %>
        </ul>

      </div>
    </div>
  <% end %>
  ```

  Note: `edit_life_path_path` does not exist as a standard route — Phase 6 will handle this differently (the link targets the Turbo Frame and loads the edit form from the controller). At this stage, you can stub the link as `"#"` and Phase 6 will wire it up properly.

### PathSet Show — Full Version

- [ ] **5.2** Replace `app/views/path_sets/show.html.erb` with the full design:

  ```erb
  <div class="container py-4">

    <%# Header %>
    <div class="d-flex justify-content-between align-items-start mb-2">
      <div>
        <h1 class="h3 mb-1">Path Set</h1>
        <p class="text-muted small mb-0">
          Generated <%= time_ago_in_words(@path_set.generated_at) %> ago
          &nbsp;·&nbsp;
          Based on your foundation as of <%= @path_set.personal_foundation.updated_at.strftime("%b %-d, %Y") %>
        </p>
      </div>
      <%= button_to "Regenerate", regenerate_path_set_path(@path_set),
            method: :post,
            class: "btn",
            style: "background-color: var(--accent); color: #fff;" %>
    </div>

    <%# View toggle: Card row / Compare two %>
    <div class="btn-group mb-4" role="group">
      <button type="button" class="btn btn-outline-secondary active" id="btn-card-row"
              onclick="document.getElementById('card-row-view').classList.remove('d-none'); document.getElementById('compare-view').classList.add('d-none'); this.classList.add('active'); document.getElementById('btn-compare').classList.remove('active');">
        Card Row
      </button>
      <button type="button" class="btn btn-outline-secondary" id="btn-compare"
              onclick="document.getElementById('compare-view').classList.remove('d-none'); document.getElementById('card-row-view').classList.add('d-none'); this.classList.add('active'); document.getElementById('btn-card-row').classList.remove('active');">
        Compare Two
      </button>
    </div>
  ```

  > **Note on the toggle buttons:** The spec calls for a Stimulus controller (`path_compare_controller`) to manage this. Phase 7 replaces these inline `onclick` calls with proper Stimulus. For this phase, the inline approach is an acceptable placeholder — but note that inline `onclick` is blocked by CSP in production. A simpler no-JS approach: use a CSS `:target` trick or just let Phase 7 wire it. If CSP is strict, skip the onclick and leave both panels visible side by side until Phase 7.

  ```erb
    <%# Card row view %>
    <div id="card-row-view">
      <div class="path-card-row mb-4">
        <% @life_paths.each do |lp| %>
          <%= render "path_card", life_path: lp %>
        <% end %>
      </div>
    </div>

    <%# Compare two view (hidden until Stimulus wires it up in Phase 7) %>
    <div id="compare-view" class="d-none" data-controller="path-compare"
         data-path-compare-base-url-value="<%= compare_path_set_path(@path_set) %>">
      <div class="row mb-3">
        <div class="col-md-5">
          <select class="form-select" data-path-compare-target="path_a_select"
                  data-action="change->path-compare#update">
            <option value="">Select Path A</option>
            <% @life_paths.each do |lp| %>
              <option value="<%= lp.id %>"><%= lp.name %></option>
            <% end %>
          </select>
        </div>
        <div class="col-md-5">
          <select class="form-select" data-path-compare-target="path_b_select"
                  data-action="change->path-compare#update">
            <option value="">Select Path B</option>
            <% @life_paths.each do |lp| %>
              <option value="<%= lp.id %>"><%= lp.name %></option>
            <% end %>
          </select>
        </div>
        <div class="col-md-2">
          <%= link_to "Compare", "#", class: "btn btn-secondary w-100 disabled",
                data: { path_compare_target: "compare_link" } %>
        </div>
      </div>
    </div>

    <%# Raw response toggle %>
    <div class="mb-4">
      <button class="btn btn-sm btn-outline-secondary" type="button"
              data-bs-toggle="collapse" data-bs-target="#raw-response">
        Show raw response
      </button>
      <div class="collapse mt-2" id="raw-response">
        <pre class="bg-dark border rounded p-3 small" style="max-height: 400px; overflow-y: auto;"><%= @path_set.gemini_raw %></pre>
      </div>
    </div>

    <%# Disclaimer — required on every path set view %>
    <div class="card disclaimer-card">
      <div class="card-body">
        <em>These paths are starting points for your own thinking. They are generated from what you wrote in your foundation, which means they reflect what you told the system about yourself, not what is true about you. Sit with each path. Talk to people walking it. Edit the texture as you learn what you actually believe. DiscoverPaths offers paths; it does not pick one for you.</em>
      </div>
    </div>

  </div>
  ```

### Compare View — Full Version

- [ ] **5.3** Replace `app/views/path_sets/compare.html.erb` with the full design:

  ```erb
  <div class="container py-4">
    <h1 class="h3 mb-1">Comparing Paths</h1>
    <p class="text-muted mb-1">Comparing <strong><%= @path_a.name %></strong> and <strong><%= @path_b.name %></strong>.</p>
    <p class="text-muted small mb-4">Switch one at a time to feel the trade-offs honestly.</p>

    <%= link_to "← Back to all paths", path_set_path(@path_set), class: "btn btn-sm btn-outline-secondary mb-4" %>

    <div class="row">
      <div class="col-md-6 mb-3">
        <%= render "path_card", life_path: @path_a %>
      </div>
      <div class="col-md-6 mb-3">
        <%= render "path_card", life_path: @path_b %>
      </div>
    </div>
  </div>
  ```

---

## RSpec Tests

- [ ] **5.4** Add one focused spec to `spec/requests/path_sets_spec.rb` (in the `compare` describe block, if it already exists from Phase 4, or add a new file):

  Verify that the compare view renders both path names:
  ```ruby
  it "renders both path names in the compare view" do
    paths = path_set.life_paths.first(2)
    get compare_path_set_path(path_set, path_a: paths[0].id, path_b: paths[1].id)
    expect(response.body).to include(paths[0].name)
    expect(response.body).to include(paths[1].name)
  end
  ```

- [ ] Verify that the disclaimer text appears on the show page:
  ```ruby
  it "includes the disclaimer on the show page" do
    get path_set_path(path_set)
    expect(response.body).to include("DiscoverPaths offers paths")
  end
  ```

- [ ] Run: `bundle exec rspec spec/requests/path_sets_spec.rb` — all must pass.

---

## Manual Tests

Start the server (`bin/dev`) before running.

- [ ] PathSet show page — all cards appear in a horizontally scrollable row.
- [ ] Scroll right — additional cards are visible; snap scrolling works.
- [ ] Each card shows: name, positioning, milestones (year 1/3/10), demands, trade-offs, real people.
- [ ] Exit Path card has a gray/secondary border and "Exit Path" badge.
- [ ] Long-Shot Path card has a lime green border and "Long-Shot Path" badge.
- [ ] Toggle to "Compare Two" — the compare selector section appears (both dropdowns visible).
- [ ] Navigate directly to `/path_sets/:id/compare?path_a=:id1&path_b=:id2` — two-column view renders both cards side by side.
- [ ] Compare view "Back to all paths" link returns to the card row.
- [ ] Mobile view (resize browser to ~375px) — compare columns stack vertically.
- [ ] Disclaimer card appears at the bottom of the show page.

---

## Done When

- [ ] `_path_card.html.erb` partial exists with all texture fields and Turbo Frame wrapper
- [ ] PathSet show page uses the card row layout with full card content
- [ ] Compare view renders two full cards side by side
- [ ] Exit Path and Long-Shot badge treatments are correct
- [ ] Disclaimer is present on the show page
- [ ] All path_sets request specs pass
