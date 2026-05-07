# Phase 2 — Data Models & Migrations

**Goal:** Create the three domain models — `PersonalFoundation`, `PathSet`, `LifePath` — with UUID-keyed migrations, model files, validations, associations, and FactoryBot factories. Run model specs before advancing.

**Spec Sections:** 3 (Data Model)  
**Guide References:** `docs/testing.md` (factories, model specs), `CLAUDE.md` (UUID PKs, no backward compat)

---

## Context at Start of Phase

Phase 1 complete. Boilerplate models (`User`, `AiTemplate`, `LlmRequest`) exist. No domain models exist yet. The `pgcrypto` extension is already enabled (required by boilerplate).

---

## Key Rules

- All PKs are UUID (`id: :uuid`). Foreign keys use `type: :uuid`.
- All timestamps are `null: false`.
- Boolean columns require `default: false, null: false`.
- Index all foreign keys. Add a unique index on `personal_foundations.user_id` (one per user).
- Never add shims or backward-compat aliases.

---

## Tasks

### Migrations

- [ ] **2.1** Generate and edit a migration for `personal_foundations`:
  ```ruby
  create_table :personal_foundations, id: :uuid do |t|
    t.references :user, null: false, foreign_key: true, type: :uuid, index: { unique: true }
    t.text :values,              null: false
    t.text :strengths,           null: false
    t.text :constraints,         null: false
    t.text :resources,           null: false
    t.text :current_trajectory,  null: false
    t.timestamps null: false
  end
  ```

- [ ] **2.2** Generate and edit a migration for `path_sets`:
  ```ruby
  create_table :path_sets, id: :uuid do |t|
    t.references :personal_foundation, null: false, foreign_key: true, type: :uuid
    t.references :user,               null: false, foreign_key: true, type: :uuid
    t.datetime :generated_at
    t.text     :gemini_raw
    t.timestamps null: false
  end
  add_index :path_sets, :user_id
  ```

- [ ] **2.3** Generate and edit a migration for `life_paths`:
  ```ruby
  create_table :life_paths, id: :uuid do |t|
    t.references :path_set, null: false, foreign_key: true, type: :uuid
    t.string  :name,         null: false
    t.string  :positioning,  null: false
    t.text    :milestones,   null: false
    t.text    :demands,      null: false
    t.text    :trade_offs,   null: false
    t.text    :real_people,  null: false
    t.boolean :is_exit_path, null: false, default: false
    t.boolean :is_long_shot, null: false, default: false
    t.integer :position
    t.timestamps null: false
  end
  add_index :life_paths, :path_set_id
  ```

- [ ] **2.4** Run `rails db:migrate` and confirm it completes with no errors.

### Models

- [ ] **2.5** Create `app/models/personal_foundation.rb`:
  ```ruby
  class PersonalFoundation < ApplicationRecord
    belongs_to :user
    has_many :path_sets, dependent: :destroy

    validates :values, :strengths, :constraints, :resources, :current_trajectory,
              presence: true, length: { minimum: 20 }
    validates :user_id, uniqueness: true
  end
  ```

- [ ] **2.6** Add to `app/models/user.rb`:
  ```ruby
  has_one  :personal_foundation, dependent: :destroy
  has_many :path_sets,           dependent: :destroy
  ```

- [ ] **2.7** Create `app/models/path_set.rb`:
  ```ruby
  class PathSet < ApplicationRecord
    belongs_to :personal_foundation
    belongs_to :user
    has_many :life_paths, dependent: :destroy

    validates :personal_foundation_id, :user_id, presence: true
  end
  ```

- [ ] **2.8** Create `app/models/life_path.rb`:
  ```ruby
  class LifePath < ApplicationRecord
    belongs_to :path_set

    validates :name, :positioning, :milestones, :demands, :trade_offs, :real_people,
              presence: true

    validate :at_most_one_exit_path_per_set
    validate :at_most_one_long_shot_per_set

    private

    def at_most_one_exit_path_per_set
      return unless is_exit_path?
      existing = path_set.life_paths.where(is_exit_path: true)
      existing = existing.where.not(id: id) if persisted?
      errors.add(:is_exit_path, "already set on another path in this set") if existing.exists?
    end

    def at_most_one_long_shot_per_set
      return unless is_long_shot?
      existing = path_set.life_paths.where(is_long_shot: true)
      existing = existing.where.not(id: id) if persisted?
      errors.add(:is_long_shot, "already set on another path in this set") if existing.exists?
    end
  end
  ```

### Factories

- [ ] **2.9** Create `spec/factories/personal_foundations.rb`:
  ```ruby
  FactoryBot.define do
    factory :personal_foundation do
      association :user
      values              { "Autonomy: I want to control my own schedule and output. Craft: I care deeply about doing things well. Honesty: I do not want to promote things I do not believe in." }
      strengths           { "Writing: I publish a weekly newsletter with 3,000 readers. Teaching: I have run workshops for two years. Systems: I redesigned an onboarding process that cut ramp time by 40%." }
      constraints         { "Financial: I need at least $80k per year. Geographic: anchored to one city for three years due to partner's role." }
      resources           { "Skills: writing, facilitation, light code. Network: 50 contacts in my field. Capital: 10 months of runway. Time: 10 hours per week for side work." }
      current_trajectory  { "If I keep doing what I am doing I will get one more promotion and keep the newsletter as a hobby indefinitely." }
    end
  end
  ```

- [ ] **2.10** Create `spec/factories/path_sets.rb`:
  ```ruby
  FactoryBot.define do
    factory :path_set do
      association :personal_foundation
      association :user
      generated_at { Time.current }

      trait :with_life_paths do
        after(:create) do |path_set|
          create(:life_path, path_set: path_set, is_exit_path: true,  position: 0)
          create(:life_path, path_set: path_set, is_long_shot: true,  position: 1)
          create(:life_path, path_set: path_set,                      position: 2)
          create(:life_path, path_set: path_set,                      position: 3)
        end
      end
    end
  end
  ```

- [ ] **2.11** Create `spec/factories/life_paths.rb`:
  ```ruby
  FactoryBot.define do
    factory :life_path do
      association :path_set
      sequence(:name)       { |n| "Path #{n}" }
      positioning           { "A one-person consulting practice focused on design systems." }
      milestones            { "Year 1: first two clients. Year 3: $120k revenue. Year 10: established practice with a waiting list." }
      demands               { "1. Consistent business development. 2. High tolerance for income variability. 3. Self-directed accountability." }
      trade_offs            { "1. No employer benefits. 2. Slower career signal than a senior title. 3. Isolation without deliberate community." }
      real_people           { "A former in-house designer who left to freelance after their company was acquired. A designer who built a product studio after fifteen years in agencies. A writer-designer who turned a newsletter into a consulting practice." }
      is_exit_path          { false }
      is_long_shot          { false }
      position              { 0 }

      trait :exit_path  do
        is_exit_path { true }
      end

      trait :long_shot do
        is_long_shot { true }
      end
    end
  end
  ```

---

## RSpec Tests

Run after completing all tasks in this phase.

- [ ] **2.12** Create `spec/models/personal_foundation_spec.rb`:
  ```ruby
  RSpec.describe PersonalFoundation, type: :model do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:path_sets).dependent(:destroy) }

    %i[values strengths constraints resources current_trajectory].each do |field|
      it { is_expected.to validate_presence_of(field) }
      it { is_expected.to validate_length_of(field).is_at_least(20) }
    end

    it "enforces one foundation per user" do
      user = create(:user)
      create(:personal_foundation, user: user)
      duplicate = build(:personal_foundation, user: user)
      expect(duplicate).not_to be_valid
    end

    it "destroys path sets when the foundation is destroyed" do
      foundation = create(:personal_foundation)
      create(:path_set, personal_foundation: foundation, user: foundation.user)
      expect { foundation.destroy }.to change(PathSet, :count).by(-1)
    end
  end
  ```

- [ ] **2.13** Create `spec/models/path_set_spec.rb`:
  ```ruby
  RSpec.describe PathSet, type: :model do
    it { is_expected.to belong_to(:personal_foundation) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:life_paths).dependent(:destroy) }
    it { is_expected.to validate_presence_of(:personal_foundation_id) }
    it { is_expected.to validate_presence_of(:user_id) }

    it "scopes path sets to the owning user" do
      user_a = create(:user)
      user_b = create(:user)
      foundation_a = create(:personal_foundation, user: user_a)
      create(:path_set, personal_foundation: foundation_a, user: user_a)
      expect(user_b.path_sets).to be_empty
    end
  end
  ```

- [ ] **2.14** Create `spec/models/life_path_spec.rb`:
  ```ruby
  RSpec.describe LifePath, type: :model do
    it { is_expected.to belong_to(:path_set) }

    %i[name positioning milestones demands trade_offs real_people].each do |field|
      it { is_expected.to validate_presence_of(field) }
    end

    describe "exit path uniqueness" do
      it "allows one exit path per set" do
        path_set = create(:path_set)
        create(:life_path, :exit_path, path_set: path_set)
        duplicate = build(:life_path, :exit_path, path_set: path_set)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:is_exit_path]).to be_present
      end
    end

    describe "long shot uniqueness" do
      it "allows one long-shot path per set" do
        path_set = create(:path_set)
        create(:life_path, :long_shot, path_set: path_set)
        duplicate = build(:life_path, :long_shot, path_set: path_set)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:is_long_shot]).to be_present
      end
    end
  end
  ```

- [ ] Run: `bundle exec rspec spec/models/personal_foundation_spec.rb spec/models/path_set_spec.rb spec/models/life_path_spec.rb` — all must pass before advancing.

---

## Manual Tests

- [ ] Open a Rails console: `rails c`
- [ ] Confirm `PersonalFoundation.new.valid?` returns `false` (validates presence).
- [ ] Confirm `User.first.build_personal_foundation(...)` assigns `user_id` automatically.
- [ ] Run `rails db:migrate:status` — all migrations should be `up`.

---

## Done When

- [ ] All three migrations run cleanly
- [ ] All three model files pass their validations
- [ ] All three factory files exist with correct defaults and traits
- [ ] All model specs pass with zero failures
