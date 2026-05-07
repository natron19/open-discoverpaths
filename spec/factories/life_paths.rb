FactoryBot.define do
  factory :life_path do
    association :path_set
    sequence(:name) { |n| "Path #{n}" }
    positioning  { "A one-person consulting practice focused on design systems." }
    milestones   { "Year 1: first two clients.\nYear 3: $120k revenue.\nYear 10: established practice with a waiting list." }
    demands      { "Consistent business development.\nHigh tolerance for income variability.\nSelf-directed accountability." }
    trade_offs   { "No employer benefits.\nSlower career signal than a senior title.\nIsolation without deliberate community." }
    real_people  { "A former in-house designer who left to freelance after their company was acquired.\nA designer who built a product studio after fifteen years in agencies.\nA writer-designer who turned a newsletter into a consulting practice." }
    is_exit_path { false }
    is_long_shot { false }
    position     { 0 }

    trait :exit_path do
      is_exit_path { true }
    end

    trait :long_shot do
      is_long_shot { true }
    end
  end
end
