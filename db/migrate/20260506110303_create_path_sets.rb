class CreatePathSets < ActiveRecord::Migration[8.1]
  def change
    create_table :path_sets, id: :uuid do |t|
      t.references :personal_foundation, null: false, foreign_key: true, type: :uuid
      t.references :user,               null: false, foreign_key: true, type: :uuid
      t.datetime :generated_at
      t.text     :gemini_raw
      t.timestamps null: false
    end
  end
end
