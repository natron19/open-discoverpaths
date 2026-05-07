require "rails_helper"

RSpec.describe LifePath, type: :model do
  describe "associations" do
    it "belongs to a path set" do
      expect(described_class.reflect_on_association(:path_set).macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    %i[name positioning milestones demands trade_offs real_people].each do |field|
      it "requires #{field}" do
        path = build(:life_path, field => "")
        expect(path).not_to be_valid
        expect(path.errors[field]).to be_present
      end
    end
  end

  describe "exit path uniqueness per set" do
    it "allows one exit path per set" do
      path_set = create(:path_set)
      create(:life_path, :exit_path, path_set: path_set)
      duplicate = build(:life_path, :exit_path, path_set: path_set)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:is_exit_path]).to be_present
    end

    it "allows an exit path to be updated without triggering the uniqueness error" do
      path_set  = create(:path_set)
      exit_path = create(:life_path, :exit_path, path_set: path_set)
      exit_path.name = "Updated Name"
      expect(exit_path).to be_valid
    end
  end

  describe "long-shot uniqueness per set" do
    it "allows one long-shot path per set" do
      path_set = create(:path_set)
      create(:life_path, :long_shot, path_set: path_set)
      duplicate = build(:life_path, :long_shot, path_set: path_set)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:is_long_shot]).to be_present
    end

    it "allows a long-shot path to be updated without triggering the uniqueness error" do
      path_set   = create(:path_set)
      long_shot  = create(:life_path, :long_shot, path_set: path_set)
      long_shot.name = "Updated Name"
      expect(long_shot).to be_valid
    end
  end
end
