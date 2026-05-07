# Phase 3 — Personal Foundation CRUD

**Goal:** Users can create, view, and edit their Personal Foundation. The dashboard shows a foundation summary (or empty state) and a placeholder path sets section. Auth is enforced on all routes.

**Spec Sections:** 4 (Routes), 5 (PersonalFoundationsController, DashboardController), 6 (Views)  
**Guide References:** `docs/turbo-stimulus-patterns.md` (form patterns), `CLAUDE.md` (no plain JS, ENV for app name)

---

## Context at Start of Phase

- Phase 1 complete: accent color, CSS, ENV vars set.
- Phase 2 complete: `PersonalFoundation`, `PathSet`, `LifePath` models and factories exist.
- Boilerplate `DashboardController#show` renders a placeholder. `ApplicationController` enforces `require_authentication`.
- `path_sets_path` and `personal_foundation_path` are referenced in the navbar (Phase 1) but not yet defined as routes — this phase defines them.

---

## Key Rules

- The `personal_foundation` resource is **singular** (`resource`, not `resources`) because each user has at most one.
- All controller actions scope to `current_user` — never query without the user scope.
- 404 (not redirect) when a user tries to access a foundation that doesn't exist.
- No plain JavaScript. Forms use standard Rails `form_with`. No `onclick`, no `<script>` tags.
- Use `turbo_stream.update()` not `replace()` for any Turbo Stream responses.

---

## Tasks

### Routes

- [ ] **3.1** Add to `config/routes.rb`:
  ```ruby
  resource :personal_foundation, only: [:new, :create, :show, :edit, :update]
  ```
  Named helpers produced: `personal_foundation_path`, `new_personal_foundation_path`, `edit_personal_foundation_path`.

### Controller

- [ ] **3.2** Create `app/controllers/personal_foundations_controller.rb`:
  ```ruby
  class PersonalFoundationsController < ApplicationController
    before_action :load_foundation, only: [:show, :edit, :update]

    def new
      if current_user.personal_foundation
        redirect_to personal_foundation_path and return
      end
      @foundation = current_user.build_personal_foundation
    end

    def create
      @foundation = current_user.build_personal_foundation(foundation_params)
      if @foundation.save
        redirect_to dashboard_path, notice: "Foundation saved."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show; end

    def edit; end

    def update
      if @foundation.update(foundation_params)
        redirect_to dashboard_path, notice: "Foundation updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def load_foundation
      @foundation = current_user.personal_foundation
      render file: Rails.public_path.join("404.html"), status: :not_found unless @foundation
    end

    def foundation_params
      params.require(:personal_foundation)
            .permit(:values, :strengths, :constraints, :resources, :current_trajectory)
    end
  end
  ```

### Views

- [ ] **3.3** Create `app/views/personal_foundations/_form.html.erb`:
  ```erb
  <%= form_with model: @foundation, url: url, method: method_override do |f| %>
    <% if @foundation.errors.any? %>
      <div class="alert alert-danger">
        <% @foundation.errors.full_messages.each do |msg| %>
          <div><%= msg %></div>
        <% end %>
      </div>
    <% end %>

    <% [
      [:values,             "Your 3–5 core values, each with a one-sentence why."],
      [:strengths,          "3 strengths with specific evidence (projects, outcomes, numbers)."],
      [:constraints,        "2–3 honest constraints: financial, geographic, family, health."],
      [:resources,          "3–5 resources you actually have: skills, network, capital, credentials, time."],
      [:current_trajectory, "One sentence: what happens if you keep doing exactly what you're doing?"]
    ].each do |field, hint| %>
      <div class="mb-4">
        <%= f.label field, class: "form-label fw-medium" %>
        <%= f.text_area field, class: "form-control", rows: 4 %>
        <div class="form-text text-muted"><%= hint %></div>
      </div>
    <% end %>

    <div class="mt-3">
      <%= f.submit submit_text, class: "btn w-100 w-md-auto", style: "background-color: var(--accent); color: #fff;" %>
    </div>
  <% end %>
  ```

- [ ] **3.4** Create `app/views/personal_foundations/new.html.erb`:
  ```erb
  <div class="container py-4">
    <div class="row">
      <div class="col-lg-8">
        <h1>Start Your Foundation</h1>
        <p class="text-muted mb-4">Your foundation is the input to every path set you generate. Be honest — vague inputs produce generic paths.</p>
        <%= render "form", url: personal_foundation_path, method_override: :post, submit_text: "Save Foundation" %>
      </div>
    </div>
  </div>
  ```

- [ ] **3.5** Create `app/views/personal_foundations/edit.html.erb`:
  ```erb
  <div class="container py-4">
    <div class="row">
      <div class="col-lg-8">
        <h1>Edit Your Foundation</h1>
        <p class="text-muted mb-4">Existing path sets are not affected. Generate a new path set after saving to see updated paths.</p>
        <%= render "form", url: personal_foundation_path, method_override: :patch, submit_text: "Update Foundation" %>
      </div>
    </div>
  </div>
  ```

- [ ] **3.6** Create `app/views/personal_foundations/show.html.erb`:
  ```erb
  <div class="container py-4">
    <div class="d-flex justify-content-between align-items-start mb-4">
      <h1>Your Foundation</h1>
      <%= link_to "Edit", edit_personal_foundation_path, class: "btn btn-outline-secondary" %>
    </div>

    <% [
      ["Values",              @foundation.values],
      ["Strengths",           @foundation.strengths],
      ["Constraints",         @foundation.constraints],
      ["Resources",           @foundation.resources],
      ["Current Trajectory",  @foundation.current_trajectory]
    ].each do |label, content| %>
      <div class="card mb-3">
        <div class="card-body">
          <h6 class="card-subtitle text-muted mb-2"><%= label %></h6>
          <p class="card-text mb-0" style="white-space: pre-wrap;"><%= content %></p>
        </div>
      </div>
    <% end %>
  </div>
  ```

### Dashboard Update

- [ ] **3.7** Update `app/controllers/dashboard_controller.rb` — `show` action:
  ```ruby
  def show
    @foundation = current_user.personal_foundation
    @path_sets  = current_user.path_sets.order(generated_at: :desc).limit(10)
  end
  ```

- [ ] **3.8** Replace `app/views/dashboard/show.html.erb`:
  ```erb
  <div class="container py-4">
    <h1>Dashboard</h1>

    <%# Foundation summary %>
    <div class="mb-5">
      <% if @foundation %>
        <div class="card">
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-start">
              <h5 class="card-title">Your Foundation</h5>
              <%= link_to "Edit", edit_personal_foundation_path, class: "btn btn-sm btn-outline-secondary" %>
            </div>
            <p class="text-muted small mb-1"><strong>Values:</strong> <%= truncate(@foundation.values, length: 120) %></p>
            <p class="text-muted small mb-0"><strong>Trajectory:</strong> <%= truncate(@foundation.current_trajectory, length: 120) %></p>
          </div>
        </div>
      <% else %>
        <div class="card border-dashed">
          <div class="card-body text-center py-5">
            <h5>Start by writing your foundation</h5>
            <p class="text-muted">Your foundation is the input for every path set. Without it, you can't generate paths.</p>
            <%= link_to "Start Your Foundation", new_personal_foundation_path, class: "btn", style: "background-color: var(--accent); color: #fff;" %>
          </div>
        </div>
      <% end %>
    </div>

    <%# Path sets section — placeholder until Phase 4 wires it up %>
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h4>Your Path Sets</h4>
      <%= button_to "Generate a New Path Set", path_sets_path,
            class: "btn",
            style: "background-color: var(--accent); color: #fff;",
            disabled: @foundation.nil?,
            data: { turbo: false } %>
    </div>

    <% if @path_sets.any? %>
      <% @path_sets.each do |ps| %>
        <div class="card mb-2">
          <div class="card-body d-flex justify-content-between align-items-center">
            <div>
              <span class="text-muted small">Generated <%= time_ago_in_words(ps.generated_at) %> ago</span>
              &nbsp;·&nbsp;
              <span class="text-muted small"><%= ps.life_paths.count %> paths</span>
            </div>
            <%= link_to "View", path_set_path(ps), class: "btn btn-sm btn-outline-secondary" %>
          </div>
        </div>
      <% end %>
    <% else %>
      <p class="text-muted">No path sets yet. Generate your first one above.</p>
    <% end %>
  </div>
  ```
  Note: `path_sets_path` and `path_set_path` will raise until Phase 4 adds those routes.

---

## RSpec Tests

Run after completing all tasks in this phase.

- [ ] **3.9** Create `spec/requests/personal_foundations_spec.rb`:

  ```ruby
  RSpec.describe "PersonalFoundations", type: :request do
    let(:user) { create(:user) }

    describe "unauthenticated access" do
      it "redirects all routes to sign in" do
        get  new_personal_foundation_path
        expect(response).to redirect_to(sign_in_path)
        get  personal_foundation_path
        expect(response).to redirect_to(sign_in_path)
        get  edit_personal_foundation_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    describe "GET /personal_foundation/new" do
      before { sign_in_as(user) }

      it "renders the form when no foundation exists" do
        get new_personal_foundation_path
        expect(response).to have_http_status(:ok)
      end

      it "redirects to show when a foundation already exists" do
        create(:personal_foundation, user: user)
        get new_personal_foundation_path
        expect(response).to redirect_to(personal_foundation_path)
      end
    end

    describe "POST /personal_foundation" do
      before { sign_in_as(user) }

      let(:valid_params) do
        {
          personal_foundation: {
            values:             "Autonomy: I want to control my own time. Craft: I care about doing things well.",
            strengths:          "Writing: published newsletter with 4,000 readers for three years. Teaching: workshops since 2022.",
            constraints:        "Financial: need at least $90k. Geographic: anchored to one city for four years.",
            resources:          "Skills: writing, facilitation. Network: 60 contacts in my field. Capital: 14 months runway.",
            current_trajectory: "If I keep doing what I am doing I will get one promotion and stay put."
          }
        }
      end

      it "creates a foundation scoped to the current user" do
        expect { post personal_foundation_path, params: valid_params }
          .to change(PersonalFoundation, :count).by(1)
        expect(PersonalFoundation.last.user).to eq(user)
      end

      it "redirects to the dashboard on success" do
        post personal_foundation_path, params: valid_params
        expect(response).to redirect_to(dashboard_path)
      end

      it "re-renders the form with invalid data" do
        post personal_foundation_path, params: { personal_foundation: { values: "short" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "GET /personal_foundation" do
      before { sign_in_as(user) }

      it "returns 200 for the foundation owner" do
        create(:personal_foundation, user: user)
        get personal_foundation_path
        expect(response).to have_http_status(:ok)
      end

      it "returns 404 when no foundation exists" do
        get personal_foundation_path
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "PATCH /personal_foundation" do
      before { sign_in_as(user) }

      it "updates only the current user's foundation" do
        foundation = create(:personal_foundation, user: user)
        patch personal_foundation_path, params: {
          personal_foundation: { values: "Updated values that are long enough to pass validation." }
        }
        expect(foundation.reload.values).to start_with("Updated values")
      end

      it "re-renders edit with invalid data" do
        create(:personal_foundation, user: user)
        patch personal_foundation_path, params: { personal_foundation: { values: "x" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
  ```

- [ ] Run: `bundle exec rspec spec/requests/personal_foundations_spec.rb` — all must pass before advancing.

---

## Manual Tests

Start the server (`bin/dev`) before running.

- [ ] Visit `/personal_foundation/new` as a signed-in user — form renders with all five fields and helper text.
- [ ] Submit with one field blank — form re-renders with a validation error message.
- [ ] Submit with all fields valid — redirected to dashboard; foundation summary card appears.
- [ ] Click Edit — foundation form pre-populated with existing data.
- [ ] Submit the edit — redirected to dashboard with updated summary.
- [ ] Dashboard shows "Generate a new Path Set" button (enabled now that a foundation exists).
- [ ] Sign in as a second user — no foundation summary visible; empty state "Start Your Foundation" CTA shows.

---

## Done When

- [ ] Singular `personal_foundation` resource routes exist
- [ ] Controller actions correctly scope to `current_user`
- [ ] Foundation form, show, and dashboard views render without errors
- [ ] Request specs all pass
