class CreateApiRequestLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :api_request_logs do |t|
      t.integer :nobservations
      t.integer :data_source_id
      t.integer :ncreates
      t.integer :ncreates_failed
      t.integer :nupdates
      t.integer :nupdates_no_change
      t.integer :nupdates_failed

      t.timestamps
    end
  end
end
