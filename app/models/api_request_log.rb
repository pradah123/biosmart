class ApiRequestLog < ApplicationRecord
  belongs_to :data_source, optional: true
end
