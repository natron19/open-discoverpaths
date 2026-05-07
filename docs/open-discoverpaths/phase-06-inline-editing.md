# Phase 6 — Inline LifePath Editing

**Goal:** Each path card has an Edit state powered by Turbo Frames. Clicking Edit swaps the card content with an editable form; saving replaces the frame with the updated card. No Gemini call is made — this is manual texture editing only.

**Spec Sections:** 5 (LifePathsController), 6 (life_paths/_edit_form)  
**Guide References:** `docs/turbo-stimulus-patterns.md` — use `update()` not `replace()` for Turbo Streams

---

## Context at Start of Phase

- Phase 5 complete: `_path_card.html.erb` wraps each card in `turbo_frame_tag "life_path_#{life_path.id}"`.
- The Edit link on the card is currently a stub (`href="#"`).
- `LifePathsController` and `life_paths/_edit_form.html.erb` do not exist yet.
- Route `resources :life_paths, only: [:update]` exists from Phase 4. An `edit` route needs to be added to serve the form.

---

## Key Rules

- **Use `turbo_stream.update()`, never `replace()`**. The card is rendered inside a Turbo Frame and must survive repeated edits.
- Scope the `LifePath` lookup through `current_user.path_sets` to prevent cross-user access.
- This action must NEVER call `GeminiService`. No `LlmRequest` record should be created.
- No plain JavaScript. The form submits via Turbo automatically because it's inside a Turbo Frame.

---

## Tasks

### Routes

- [ ] **6.1** Update the `life_paths` routes in `config/routes.rb` to add `edit`:
  ```ruby
  resources :life_paths, only: [:edit, :update]
  ```

### Controller

- [ ] **6.2** Create `app/controllers/life_paths_controller.rb`:

  ```ruby
  class LifePathsController < ApplicationController
    before_action :load_life_path

    def edit
      # renders life_paths/edit.html.erb inside the Turbo Frame
    end

    def update
      if @life_path.update(life_path_params)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update(
              "life_path_#{@life_path.id}",
              partial: "path_sets/path_card",
              locals: { life_path: @life_path }
            )
          end
          format.html { redirect_to path_set_path(@life_path.path_set) }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update(
              "life_path_#{@life_path.id}",
              partial: "life_paths/edit_form",
              locals: { life_path: @life_path }
            )
          end
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    private

    def load_life_path
      @life_path = current_user.path_sets
                               .joins(:life_paths)
                               .where(life_paths: { id: params[:id] })
                               .then { LifePath.where(id: params[:id], path_set: _1) }
                               .first
      render file: Rails.public_path.join("404.html"), status: :not_found unless @life_path
    end

    def life_path_params
      params.require(:life_path)
            .permit(:name, :positioning, :milestones, :demands, :trade_offs, :real_people)
    end
  end
  ```

  Simpler scoping alternative if the join syntax feels awkward:
  ```ruby
  def load_life_path
    path_set_ids = current_user.path_sets.pluck(:id)
    @life_path   = LifePath.find_by(id: params[:id], path_set_id: path_set_ids)
    render file: Rails.public_path.join("404.html"), status: :not_found unless @life_path
  end
  ```

### Edit Form View

- [ ] **6.3** Create `app/views/life_paths/edit.html.erb` — renders the edit form inside the Turbo Frame for direct navigation:
  ```erb
  <%= turbo_frame_tag "life_path_#{@life_path.id}" do %>
    <%= render "edit_form", life_path: @life_path %>
  <% end %>
  ```

- [ ] **6.4** Create `app/views/life_paths/_edit_form.html.erb`:

  ```erb
  <%= form_with model: life_path, url: life_path_path(life_path), method: :patch,
        data: { turbo_frame: "life_path_#{life_path.id}" } do |f| %>

    <% if life_path.errors.any? %>
      <div class="alert alert-danger small">
        <% life_path.errors.full_messages.each do |msg| %>
          <div><%= msg %></div>
        <% end %>
      </div>
    <% end %>

    <div class="mb-3">
      <%= f.label :name, class: "form-label fw-medium small" %>
      <%= f.text_field :name, class: "form-control form-control-sm" %>
    </div>

    <div class="mb-3">
      <%= f.label :positioning, class: "form-label fw-medium small" %>
      <%= f.text_area :positioning, class: "form-control form-control-sm", rows: 2 %>
    </div>

    <div class="mb-3">
      <%= f.label :milestones, class: "form-label fw-medium small" %>
      <%= f.text_area :milestones, class: "form-control form-control-sm", rows: 4 %>
      <div class="form-text text-muted">One milestone per line: Year 1, Year 3, Year 10.</div>
    </div>

    <div class="mb-3">
      <%= f.label :demands, class: "form-label fw-medium small" %>
      <%= f.text_area :demands, class: "form-control form-control-sm", rows: 3 %>
      <div class="form-text text-muted">One demand per line.</div>
    </div>

    <div class="mb-3">
      <%= f.label :trade_offs, class: "form-label fw-medium small" %>
      <%= f.text_area :trade_offs, class: "form-control form-control-sm", rows: 3 %>
      <div class="form-text text-muted">One trade-off per line.</div>
    </div>

    <div class="mb-3">
      <%= f.label :real_people, class: "form-label fw-medium small" %>
      <%= f.text_area :real_people, class: "form-control form-control-sm", rows: 3 %>
      <div class="form-text text-muted">One profile per line.</div>
    </div>

    <div class="d-flex gap-2">
      <%= f.submit "Save", class: "btn btn-sm", style: "background-color: var(--accent); color: #fff;" %>
      <%= link_to "Cancel", path_set_path(life_path.path_set), class: "btn btn-sm btn-outline-secondary",
            data: { turbo_frame: "life_path_#{life_path.id}" } %>
    </div>
  <% end %>
  ```

### Wire the Edit Link

- [ ] **6.5** Update `app/views/path_sets/_path_card.html.erb` — replace the stub Edit link with:
  ```erb
  <%= link_to "Edit", edit_life_path_path(life_path),
        data: { turbo_frame: "life_path_#{life_path.id}" },
        class: "btn btn-sm btn-outline-secondary py-0 px-2" %>
  ```

---

## RSpec Tests

- [ ] **6.6** Create `spec/requests/life_paths_spec.rb`:

  ```ruby
  RSpec.describe "LifePaths", type: :request do
    let(:user)       { create(:user) }
    let(:foundation) { create(:personal_foundation, user: user) }
    let(:path_set)   { create(:path_set, :with_life_paths, user: user, personal_foundation: foundation) }
    let(:life_path)  { path_set.life_paths.first }

    describe "unauthenticated access" do
      it "redirects update to sign in" do
        patch life_path_path(life_path), params: { life_path: { name: "New Name" } }
        expect(response).to redirect_to(sign_in_path)
      end
    end

    describe "PATCH /life_paths/:id" do
      before { sign_in_as(user) }

      it "updates the life path texture" do
        patch life_path_path(life_path),
              params: { life_path: { name: "Updated Name" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(life_path.reload.name).to eq("Updated Name")
      end

      it "responds with a Turbo Stream" do
        patch life_path_path(life_path),
              params: { life_path: { name: "Turbo Test" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.content_type).to include("turbo-stream")
      end

      it "does NOT create an LlmRequest" do
        expect {
          patch life_path_path(life_path),
                params: { life_path: { name: "No AI" } },
                headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.not_to change(LlmRequest, :count)
      end

      it "returns 404 when a different signed-in user attempts the update" do
        other_user = create(:user)
        sign_in_as(other_user)
        patch life_path_path(life_path),
              params: { life_path: { name: "Hijack" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:not_found)
      end

      it "does not update a blank name" do
        patch life_path_path(life_path),
              params: { life_path: { name: "" } },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(life_path.reload.name).not_to be_blank
      end
    end
  end
  ```

- [ ] Run: `bundle exec rspec spec/requests/life_paths_spec.rb` — all must pass before advancing.

---

## Manual Tests

Start the server (`bin/dev`) before running.

- [ ] On a PathSet show page, click "Edit" on a card — form appears in-place, replacing the card content.
- [ ] Edit the name field, click Save — card updates with new name, no full page reload.
- [ ] Click Edit again on the same card — form appears with the updated content (confirms `update()` is used, not `replace()`).
- [ ] Click Cancel — card view restores without changes.
- [ ] Submit edit with blank name — validation error appears inside the card.
- [ ] Check `/admin/llm_requests` after editing — no new `LlmRequest` rows were created.
- [ ] Try the edit URL directly as a second signed-in user — confirm 404.

---

## Done When

- [ ] `edit` and `update` routes exist for `life_paths`
- [ ] `LifePathsController` scopes all lookups to `current_user`
- [ ] Inline edit form renders inside the Turbo Frame on the card
- [ ] Save replaces the card with updated content (Turbo Stream update)
- [ ] Cancel restores the card view
- [ ] No `LlmRequest` created on edit
- [ ] All life_paths request specs pass
