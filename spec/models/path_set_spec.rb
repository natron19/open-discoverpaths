require "rails_helper"

RSpec.describe PathSet, type: :model do
  describe "associations" do
    it "belongs to a personal foundation" do
      expect(described_class.reflect_on_association(:personal_foundation).macro).to eq(:belongs_to)
    end

    it "belongs to a user" do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it "has many life paths" do
      reflection = described_class.reflect_on_association(:life_paths)
      expect(reflection.macro).to eq(:has_many)
      expect(reflection.options[:dependent]).to eq(:destroy)
    end
  end

  describe "validations" do
    it "requires personal_foundation_id" do
      path_set = build(:path_set, personal_foundation: nil)
      expect(path_set).not_to be_valid
    end

    it "requires user_id" do
      path_set = build(:path_set, user: nil)
      expect(path_set).not_to be_valid
    end
  end

  describe "scoping" do
    it "does not expose another user's path sets" do
      user_a = create(:user)
      user_b = create(:user)
      foundation = create(:personal_foundation, user: user_a)
      create(:path_set, personal_foundation: foundation, user: user_a)
      expect(user_b.path_sets).to be_empty
    end
  end
end
