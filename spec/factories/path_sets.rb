FactoryBot.define do
  factory :path_set do
    association :personal_foundation
    association :user
    generated_at { Time.current }

    trait :with_life_paths do
      after(:create) do |path_set|
        create(:life_path, :exit_path,  path_set: path_set, position: 0)
        create(:life_path, :long_shot,  path_set: path_set, position: 1)
        create(:life_path,              path_set: path_set, position: 2)
        create(:life_path,              path_set: path_set, position: 3)
      end
    end
  end
end
