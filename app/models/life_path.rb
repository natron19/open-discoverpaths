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
