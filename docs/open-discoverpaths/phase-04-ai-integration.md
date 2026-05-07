# Phase 4 — AI Template, Path Generation & PathSets

**Goal:** Seed the AI template, implement `PathSetsController` with full Gemini integration and JSON parsing, and display a basic PathSet show page with the disclaimer. After this phase, a user can generate a real Path Set from their foundation.

**Spec Sections:** 4 (Routes), 5 (PathSetsController), 7 (AI template), 8 (disclaimer), 10 (seeds)  
**Guide References:** `docs/ai-templates.md` (calling GeminiService), `docs/ai-guardrails.md` (error handling), `docs/testing.md` (Gemini stub)

---

## Context at Start of Phase

- Phase 3 complete: `PersonalFoundationsController`, foundation form, dashboard with empty path sets section.
- `GeminiService`, `AiGatekeeper`, `AiBudgetChecker` all exist in the boilerplate.
- `spec/support/gemini_test_double.rb` exists with `gemini_returns(text)` and `gemini_raises(error_class)` helpers.
- No `PathSetsController`, no path set routes, no AI template seed yet.

---

## Key Rules

- **Never call the Gemini API directly.** Always use `GeminiService.generate(template:, variables:)`.
- **Always rescue all four GeminiService error types** (`BudgetExceededError`, `GatekeeperError`, `TimeoutError`, `GeminiError`) and render `shared/ai_error`.
- Use `gemini-2.5-flash` (not `gemini-2.0-flash` — the latter returns 404 on new API keys).
- Wrap `PathSet` + `LifePath` creation in a transaction. On error, rollback preserves existing paths.
- Store the raw Gemini response in `path_sets.gemini_raw` for the "Show raw response" toggle.
- Use `turbo_stream.update()` not `replace()` if any Turbo Stream responses are added.

---

## Tasks

### Seeds

- [ ] **4.1** Update `db/seeds.rb` — add the `discoverpaths_pathset_v1` AI template using `find_or_create_by!`:

  ```ruby
  AiTemplate.find_or_create_by!(name: "discoverpaths_pathset_v1") do |t|
    t.description = "Generates 4 to 6 candidate life paths from a Personal Foundation. Returns JSON. Strict offer-not-prescribe framing."

    t.system_prompt = <<~PROMPT
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
    PROMPT

    t.user_prompt_template = <<~TEMPLATE
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
    TEMPLATE

    t.model             = "gemini-2.5-flash"
    t.max_output_tokens = 3000
    t.temperature       = 0.8
    t.notes = <<~NOTES
      Watch for these failure modes:
      1. Paths too similar — increase temperature or add an instruction that paths must differ along at least two dimensions.
      2. Model invents constraints the user did not state — reinforce in system prompt if it persists.
      3. Model tries to rank or recommend — watch gemini_raw for "recommended", "best", "should choose".
      4. Model names specific real people in real_people — system prompt forbids this; reinforce if needed.
      5. JSON parse failures — rare with gemini-2.5-flash but possible; controller wraps in begin/rescue.
    NOTES
  end
  ```

- [ ] **4.2** Add the sample `PersonalFoundation` seed for the admin demo user. Use `find_or_create_by` so re-seeding is safe:
  ```ruby
  admin = User.find_by!(email: "demo@example.com")

  unless admin.personal_foundation
    admin.create_personal_foundation!(
      values: "Autonomy: I want to control my own time. Craft: I care about doing things well, not fast. Family: my partner and I want to keep weekends free. Honesty: I do not want to sell things I do not believe in. Curiosity: I read across fields and want a job that rewards that.",
      strengths: "Writing: I have published a newsletter for three years with 4,000 subscribers. Systems thinking: at my last role I redesigned an onboarding process that cut new-hire ramp from 90 days to 45. Teaching: I have run weekend workshops for early-career designers since 2022 and consistently get high feedback.",
      constraints: "Financial: I need at least $90k a year to stay in our current city without family support. Geographic: my partner's job anchors us to one of three U.S. metros for the next four years. Family: we are planning to have a child within two years and I want to be present for the early years.",
      resources: "Skills: writing, design systems, public speaking, light Ruby and SQL. Networks: 60-ish design leaders I know personally from a community I co-run. Capital: about 14 months of runway in savings. Credentials: a portfolio, a small audience, a few notable past employers. Time: about 8 hours of side-project capacity per week.",
      current_trajectory: "If I keep doing what I am doing, I will stay in my current senior design role for another two years, get one promotion, and continue running the newsletter and workshops on the side without ever testing whether either could be the main thing."
    )
  end
  ```

- [ ] Run `rails db:seed` and verify no errors.

### Routes

- [ ] **4.3** Add to `config/routes.rb`:
  ```ruby
  resources :path_sets, only: [:create, :show] do
    member do
      post :regenerate
      get  :compare
    end
  end
  resources :life_paths, only: [:update]
  ```

### JSON Parser

- [ ] **4.4** Create a private parsing helper in `PathSetsController` (or extract to `app/services/path_set_parser.rb`) that:
  - Accepts the raw Gemini response string
  - Calls `JSON.parse(raw)` wrapped in `begin/rescue JSON::ParserError` — raises `GeminiService::GeminiError` on failure
  - Validates exactly one `is_exit_path: true` and one `is_long_shot: true`; if violated, picks the first occurrence per flag, clears the rest, and logs a warning with `Rails.logger.warn`
  - Returns an array of attribute hashes ready for `LifePath` creation

  Example structure:
  ```ruby
  def parse_paths(raw)
    data = JSON.parse(raw)
    paths = data["paths"]
    raise GeminiService::GeminiError, "Invalid response structure" unless paths.is_a?(Array)

    # Enforce at-most-one constraints
    enforce_single_flag!(paths, "is_exit_path")
    enforce_single_flag!(paths, "is_long_shot")
    paths
  rescue JSON::ParserError => e
    raise GeminiService::GeminiError, "JSON parse failed: #{e.message}"
  end

  def enforce_single_flag!(paths, flag)
    flagged = paths.select { |p| p[flag] }
    return if flagged.length <= 1
    Rails.logger.warn "DiscoverPaths: Gemini returned #{flagged.length} paths with #{flag}=true; keeping first."
    flagged[1..].each { |p| p[flag] = false }
  end
  ```

### Controller

- [ ] **4.5** Create `app/controllers/path_sets_controller.rb`:

  ```ruby
  class PathSetsController < ApplicationController
    before_action :load_path_set, only: [:show, :regenerate, :compare]

    def create
      foundation = current_user.personal_foundation
      return render file: Rails.public_path.join("404.html"), status: :not_found unless foundation

      raw = GeminiService.generate(
        template: "discoverpaths_pathset_v1",
        variables: foundation_variables(foundation)
      )

      @path_set = build_path_set(foundation, raw)

      redirect_to path_set_path(@path_set)
    rescue GeminiService::BudgetExceededError
      render partial: "shared/ai_error", locals: { error_type: :budget_exceeded }
    rescue GeminiService::GatekeeperError
      render partial: "shared/ai_error", locals: { error_type: :gatekeeper_blocked }
    rescue GeminiService::TimeoutError
      render partial: "shared/ai_error", locals: { error_type: :timeout }
    rescue GeminiService::GeminiError
      render partial: "shared/ai_error", locals: { error_type: :error }
    end

    def show
      @life_paths = @path_set.life_paths.order(:position)
    end

    def regenerate
      foundation = current_user.personal_foundation
      return render file: Rails.public_path.join("404.html"), status: :not_found unless foundation

      raw = GeminiService.generate(
        template: "discoverpaths_pathset_v1",
        variables: foundation_variables(foundation)
      )

      ActiveRecord::Base.transaction do
        @path_set.life_paths.destroy_all
        paths_data = parse_paths(raw)
        paths_data.each_with_index do |attrs, i|
          @path_set.life_paths.create!(life_path_attrs(attrs, i))
        end
        @path_set.update!(gemini_raw: raw, generated_at: Time.current)
      end

      redirect_to path_set_path(@path_set), notice: "Path set regenerated."
    rescue GeminiService::BudgetExceededError
      render partial: "shared/ai_error", locals: { error_type: :budget_exceeded }
    rescue GeminiService::GatekeeperError
      render partial: "shared/ai_error", locals: { error_type: :gatekeeper_blocked }
    rescue GeminiService::TimeoutError
      render partial: "shared/ai_error", locals: { error_type: :timeout }
    rescue GeminiService::GeminiError
      render partial: "shared/ai_error", locals: { error_type: :error }
    end

    def compare
      path_a_id = params[:path_a]
      path_b_id = params[:path_b]

      if path_a_id.blank? || path_b_id.blank?
        return redirect_to path_set_path(@path_set)
      end

      @path_a = @path_set.life_paths.find_by(id: path_a_id)
      @path_b = @path_set.life_paths.find_by(id: path_b_id)

      return render file: Rails.public_path.join("404.html"), status: :not_found unless @path_a && @path_b
    end

    private

    def load_path_set
      @path_set = current_user.path_sets.includes(:life_paths, :personal_foundation).find_by(id: params[:id])
      render file: Rails.public_path.join("404.html"), status: :not_found unless @path_set
    end

    def foundation_variables(foundation)
      {
        values:             foundation.values,
        strengths:          foundation.strengths,
        constraints:        foundation.constraints,
        resources:          foundation.resources,
        current_trajectory: foundation.current_trajectory
      }
    end

    def build_path_set(foundation, raw)
      paths_data = parse_paths(raw)
      ActiveRecord::Base.transaction do
        path_set = current_user.path_sets.create!(
          personal_foundation: foundation,
          gemini_raw:          raw,
          generated_at:        Time.current
        )
        paths_data.each_with_index do |attrs, i|
          path_set.life_paths.create!(life_path_attrs(attrs, i))
        end
        path_set
      end
    end

    def life_path_attrs(attrs, position)
      milestones_text = [
        "Year 1: #{attrs.dig('milestones', 'year_1')}",
        "Year 3: #{attrs.dig('milestones', 'year_3')}",
        "Year 10: #{attrs.dig('milestones', 'year_10')}"
      ].join("\n")

      {
        name:         attrs["name"],
        positioning:  attrs["positioning"],
        milestones:   milestones_text,
        demands:      attrs["demands"].join("\n"),
        trade_offs:   attrs["trade_offs"].join("\n"),
        real_people:  attrs["real_people"].join("\n"),
        is_exit_path: attrs["is_exit_path"] || false,
        is_long_shot: attrs["is_long_shot"] || false,
        position:     position
      }
    end

    def parse_paths(raw)
      data = JSON.parse(raw)
      paths = data["paths"]
      raise GeminiService::GeminiError, "Invalid response structure" unless paths.is_a?(Array)
      enforce_single_flag!(paths, "is_exit_path")
      enforce_single_flag!(paths, "is_long_shot")
      paths
    rescue JSON::ParserError => e
      raise GeminiService::GeminiError, "JSON parse failed: #{e.message}"
    end

    def enforce_single_flag!(paths, flag)
      flagged = paths.select { |p| p[flag] }
      return if flagged.length <= 1
      Rails.logger.warn "DiscoverPaths: Gemini returned #{flagged.length} paths with #{flag}=true; keeping first."
      flagged[1..].each { |p| p[flag] = false }
    end
  end
  ```

### Views (Basic — Full Styling in Phase 5)

- [ ] **4.6** Create `app/views/path_sets/show.html.erb` — functional working version:
  ```erb
  <div class="container py-4">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <div>
        <h1 class="h3 mb-1">Path Set</h1>
        <p class="text-muted mb-0 small">
          Generated <%= time_ago_in_words(@path_set.generated_at) %> ago
        </p>
      </div>
      <%= button_to "Regenerate", regenerate_path_set_path(@path_set),
            method: :post, class: "btn",
            style: "background-color: var(--accent); color: #fff;" %>
    </div>

    <div class="path-card-row mb-4">
      <% @life_paths.each do |lp| %>
        <div class="card <%= 'exit-path' if lp.is_exit_path? %> <%= 'long-shot' if lp.is_long_shot? %>">
          <div class="card-body">
            <% if lp.is_exit_path? %>
              <span class="badge bg-secondary mb-2">Exit Path</span>
            <% elsif lp.is_long_shot? %>
              <span class="badge badge-accent mb-2">Long-Shot Path</span>
            <% end %>
            <h5 class="card-title"><%= lp.name %></h5>
            <p class="card-text text-muted"><%= lp.positioning %></p>
          </div>
        </div>
      <% end %>
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

    <%# Disclaimer (required on every path set view) %>
    <div class="card disclaimer-card">
      <div class="card-body">
        <em>These paths are starting points for your own thinking. They are generated from what you wrote in your foundation, which means they reflect what you told the system about yourself, not what is true about you. Sit with each path. Talk to people walking it. Edit the texture as you learn what you actually believe. DiscoverPaths offers paths; it does not pick one for you.</em>
      </div>
    </div>
  </div>
  ```

- [ ] **4.7** Create `app/views/path_sets/compare.html.erb` — basic version (full styling in Phase 5):
  ```erb
  <div class="container py-4">
    <h1 class="h3 mb-1">Comparing Paths</h1>
    <p class="text-muted mb-4">Switch one at a time to feel the trade-offs honestly.</p>
    <%= link_to "← Back to all paths", path_set_path(@path_set), class: "btn btn-sm btn-outline-secondary mb-4" %>

    <div class="row">
      <div class="col-md-6 mb-3">
        <div class="card h-100">
          <div class="card-body">
            <h5><%= @path_a.name %></h5>
            <p class="text-muted"><%= @path_a.positioning %></p>
          </div>
        </div>
      </div>
      <div class="col-md-6 mb-3">
        <div class="card h-100">
          <div class="card-body">
            <h5><%= @path_b.name %></h5>
            <p class="text-muted"><%= @path_b.positioning %></p>
          </div>
        </div>
      </div>
    </div>
  </div>
  ```

---

## RSpec Tests

The Gemini stub fixture for these specs needs a valid 5-path JSON string. Create or add to `spec/support/gemini_test_double.rb`:

```ruby
SAMPLE_PATHSET_JSON = JSON.generate({
  paths: [
    { name: "Independent Consultant", positioning: "Run a one-person design consulting practice.",
      milestones: { year_1: "First two clients.", year_3: "$100k revenue.", year_10: "Waiting list." },
      demands: ["Business development", "Income variability tolerance", "Self-discipline"],
      trade_offs: ["No benefits", "Slower career signal", "Isolation"],
      real_people: ["A former in-house designer who left to freelance.", "A studio owner with 15 years agency background.", "A writer-designer who turned a newsletter into consulting."],
      is_exit_path: false, is_long_shot: false },
    { name: "Newsletter + Courses", positioning: "Build an audience-driven education business.",
      milestones: { year_1: "First paid course.", year_3: "200 students.", year_10: "Sustainable course library." },
      demands: ["Consistent publishing", "Product discipline", "Patience with slow growth"],
      trade_offs: ["Unpredictable income", "Public exposure", "Long feedback loops"],
      real_people: ["A designer who left to teach online.", "A writer who turned a newsletter into courses.", "A developer who built paid workshops."],
      is_exit_path: false, is_long_shot: false },
    { name: "Design Leadership", positioning: "Move into a Head of Design role at a mid-stage startup.",
      milestones: { year_1: "Head of Design title.", year_3: "Team of five.", year_10: "VP or CPO." },
      demands: ["Political navigation", "People management", "Equity risk tolerance"],
      trade_offs: ["Less craft time", "Company outcome risk", "Slower if company fails"],
      real_people: ["A senior IC who moved into management.", "A consultant who joined a startup as design lead.", "A head of design who made VP after an acquisition."],
      is_exit_path: false, is_long_shot: false },
    { name: "Return to Stable Employment", positioning: "Take a well-scoped senior IC role at a large company.",
      milestones: { year_1: "Role secured.", year_3: "One promotion.", year_10: "Staff or principal title." },
      demands: ["Accepting pace", "Corporate navigation", "Side project discipline"],
      trade_offs: ["Less autonomy", "Slower wealth building", "Newsletter stays a hobby"],
      real_people: ["A freelancer who returned to full-time for stability.", "A startup veteran who joined a larger company.", "A consultant who took an in-house role for the benefits."],
      is_exit_path: true, is_long_shot: false },
    { name: "Build a SaaS Product", positioning: "Turn a workflow problem into a small SaaS for design teams.",
      milestones: { year_1: "10 paying customers.", year_3: "$5k MRR.", year_10: "Acquired or sustainable." },
      demands: ["Technical learning or co-founder", "Long unpaid runway", "Product obsession"],
      trade_offs: ["High failure rate", "Financial risk", "Years before payoff"],
      real_people: ["A designer who built a tool for their old team.", "A solo founder with 8 years runway.", "A design consultant who productized a service."],
      is_exit_path: false, is_long_shot: true }
  ]
}).freeze
```

- [ ] **4.8** Create `spec/requests/path_sets_spec.rb`:

  ```ruby
  RSpec.describe "PathSets", type: :request do
    let(:user)       { create(:user) }
    let(:foundation) { create(:personal_foundation, user: user) }

    before { foundation } # ensure it exists

    describe "unauthenticated access" do
      it "redirects create to sign in" do
        post path_sets_path
        expect(response).to redirect_to(sign_in_path)
      end

      it "redirects show to sign in" do
        get path_set_path(SecureRandom.uuid)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    describe "POST /path_sets" do
      before do
        sign_in_as(user)
        allow(GeminiService).to receive(:generate).and_return(SAMPLE_PATHSET_JSON)
      end

      it "creates a PathSet with 5 LifePath children" do
        expect { post path_sets_path }
          .to change(PathSet, :count).by(1)
          .and change(LifePath, :count).by(5)
      end

      it "scopes the PathSet to the current user" do
        post path_sets_path
        expect(PathSet.last.user).to eq(user)
      end

      it "creates an LlmRequest with status success" do
        post path_sets_path
        expect(LlmRequest.last.status).to eq("success")
      end

      it "redirects to the path set show page" do
        post path_sets_path
        expect(response).to redirect_to(path_set_path(PathSet.last))
      end

      it "renders ai_error on GeminiError" do
        allow(GeminiService).to receive(:generate).and_raise(GeminiService::GeminiError, "test error")
        post path_sets_path
        expect(response.body).to include("ai_error")
      end

      it "returns 404 if the user has no foundation" do
        user_without_foundation = create(:user)
        sign_in_as(user_without_foundation)
        post path_sets_path
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /path_sets/:id" do
      let(:path_set) { create(:path_set, :with_life_paths, user: user, personal_foundation: foundation) }

      before { sign_in_as(user) }

      it "returns 200 for the owner" do
        get path_set_path(path_set)
        expect(response).to have_http_status(:ok)
      end

      it "returns 404 for a different user" do
        other_user = create(:user)
        sign_in_as(other_user)
        get path_set_path(path_set)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "POST /path_sets/:id/regenerate" do
      let(:path_set) { create(:path_set, :with_life_paths, user: user, personal_foundation: foundation) }

      before do
        sign_in_as(user)
        allow(GeminiService).to receive(:generate).and_return(SAMPLE_PATHSET_JSON)
      end

      it "destroys old life paths and creates new ones" do
        old_count = path_set.life_paths.count
        post regenerate_path_set_path(path_set)
        expect(path_set.reload.life_paths.count).to eq(5)
      end

      it "preserves the path set record" do
        expect { post regenerate_path_set_path(path_set) }
          .not_to change(PathSet, :count)
      end
    end

    describe "GET /path_sets/:id/compare" do
      let(:path_set) { create(:path_set, :with_life_paths, user: user, personal_foundation: foundation) }

      before { sign_in_as(user) }

      it "returns 200 with valid path_a and path_b params" do
        paths = path_set.life_paths.first(2)
        get compare_path_set_path(path_set, path_a: paths[0].id, path_b: paths[1].id)
        expect(response).to have_http_status(:ok)
      end

      it "redirects to show when path_a or path_b is missing" do
        get compare_path_set_path(path_set)
        expect(response).to redirect_to(path_set_path(path_set))
      end

      it "returns 404 if path_a does not belong to this path set" do
        other_foundation = create(:personal_foundation)
        other_path_set   = create(:path_set, :with_life_paths, user: user, personal_foundation: other_foundation)
        path_b = path_set.life_paths.first
        path_a = other_path_set.life_paths.first
        get compare_path_set_path(path_set, path_a: path_a.id, path_b: path_b.id)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
  ```

- [ ] Run: `bundle exec rspec spec/requests/path_sets_spec.rb` — all must pass before advancing.

---

## Manual Tests

Start the server (`bin/dev`) before running. Requires a valid `GEMINI_API_KEY` in `.env`.

- [ ] Visit `/admin/ai_templates` — `discoverpaths_pathset_v1` appears.
- [ ] Open the template in admin — test panel with sample foundation text returns valid JSON from Gemini.
- [ ] From the dashboard, click "Generate a new Path Set" — page redirects to the PathSet show page.
- [ ] Confirm 4–6 path cards appear with names and positioning.
- [ ] Expand "Show raw response" — JSON is visible and valid.
- [ ] Disclaimer card appears at the bottom of the page.
- [ ] Click "Regenerate" — new paths replace old ones; old path set record is reused.
- [ ] Sign in as a second user; navigate directly to the first user's PathSet URL — confirm 404.
- [ ] Visit `/admin/llm_requests` — each generation appears as a logged request with status `success`.

---

## Done When

- [ ] `discoverpaths_pathset_v1` AI template seeded successfully
- [ ] Sample `PersonalFoundation` seeded for demo user
- [ ] Routes for `path_sets` and `life_paths` exist
- [ ] `PathSetsController` creates, shows, regenerates, and compares path sets
- [ ] Gemini errors render `shared/ai_error` gracefully
- [ ] All request specs pass
