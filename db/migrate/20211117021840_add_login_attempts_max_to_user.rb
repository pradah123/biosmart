class AddLoginAttemptsMaxToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :login_attempts_max, :integer, default: 5
  end
end
