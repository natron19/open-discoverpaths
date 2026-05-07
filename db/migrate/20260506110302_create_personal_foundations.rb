class CreatePersonalFoundations < ActiveRecord::Migration[8.1]
  def change
    create_table :personal_foundations, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.text :values,             null: false
      t.text :strengths,          null: false
      t.text :constraints,        null: false
      t.text :resources,          null: false
      t.text :current_trajectory, null: false
      t.timestamps null: false
    end
  end
end
