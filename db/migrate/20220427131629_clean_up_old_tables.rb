class CleanUpOldTables < ActiveRecord::Migration[6.1]
  def change
    drop_table :articles
    drop_table :attachments
    drop_table :categories
    drop_table :comments
    drop_table :ingredients
    drop_table :ingredients_steps
    drop_table :ratings
    drop_table :steps
    drop_table :views
  end
end
