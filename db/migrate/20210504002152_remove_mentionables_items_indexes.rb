class MentionablesSlugDataConsolidation < ActiveRecord::Migration[6.0]
  def change
    remove_index :mentionable_items, :name_slug
    remove_index :mentionable_items, :url
  end
end
