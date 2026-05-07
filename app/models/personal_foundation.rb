class PersonalFoundation < ApplicationRecord
  belongs_to :user
  has_many :path_sets, dependent: :destroy

  validates :values, :strengths, :constraints, :resources, :current_trajectory,
            presence: true, length: { minimum: 20 }
  validates :user_id, uniqueness: true
end
