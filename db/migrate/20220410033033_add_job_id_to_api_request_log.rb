class AddJobIdToApiRequestLog < ActiveRecord::Migration[6.1]
  def change
    add_column :api_request_logs, :job_id, :integer
  end
end
