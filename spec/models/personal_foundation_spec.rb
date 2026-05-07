require "rails_helper"

RSpec.describe PersonalFoundation, type: :model do
  describe "associations" do
    it "belongs to a user" do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it "has many path sets" do
      reflection = described_class.reflect_on_association(:path_sets)
      expect(reflection.macro).to eq(:has_many)
      expect(reflection.options[:dependent]).to eq(:destroy)
    end

    it "destroys associated path sets when the foundation is destroyed" do
      foundation = create(:personal_foundation)
      create(:path_set, personal_foundation: foundation, user: foundation.user)
      expect { foundation.destroy }.to change(PathSet, :count).by(-1)
    end
  end

  describe "validations" do
    %i[values strengths constraints resources current_trajectory].each do |field|
      it "requires #{field}" do
        foundation = build(:personal_foundation, field => "")
        expect(foundation).not_to be_valid
        expect(foundation.errors[field]).to be_present
      end

      it "requires #{field} to be at least 20 characters" do
        foundation = build(:personal_foundation, field => "too short")
        expect(foundation).not_to be_valid
      end
    end

    it "enforces one foundation per user" do
      user = create(:user)
      create(:personal_foundation, user: user)
      duplicate = build(:personal_foundation, user: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it "allows different users to each have a foundation" do
      create(:personal_foundation, user: create(:user))
      second = build(:personal_foundation, user: create(:user))
      expect(second).to be_valid
    end
  end
end
