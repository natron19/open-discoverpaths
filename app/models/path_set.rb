class PathSet < ApplicationRecord
  belongs_to :personal_foundation
  belongs_to :user
  has_many :life_paths, dependent: :destroy

  validates :personal_foundation_id, :user_id, presence: true
end
