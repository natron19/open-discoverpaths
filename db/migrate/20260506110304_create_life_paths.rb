class CreateLifePaths < ActiveRecord::Migration[8.1]
  def change
    create_table :life_paths, id: :uuid do |t|
      t.references :path_set, null: false, foreign_key: true, type: :uuid
      t.string  :name,         null: false
      t.string  :positioning,  null: false
      t.text    :milestones,   null: false
      t.text    :demands,      null: false
      t.text    :trade_offs,   null: false
      t.text    :real_people,  null: false
      t.boolean :is_exit_path, null: false, default: false
      t.boolean :is_long_shot, null: false, default: false
      t.integer :position
      t.timestamps null: false
    end
  end
end
