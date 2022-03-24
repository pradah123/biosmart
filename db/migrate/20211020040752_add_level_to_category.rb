class AddLevelToCategory < ActiveRecord::Migration[6.1]
  def change
    add_column :categories, :level, :integer
  end
end
