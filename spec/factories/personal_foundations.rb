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
