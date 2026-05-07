class AddResponseJsonToAiTemplates < ActiveRecord::Migration[8.1]
  def change
    add_column :ai_templates, :response_json, :boolean, default: false, null: false
  end
end
