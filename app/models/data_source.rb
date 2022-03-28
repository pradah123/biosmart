class DataSource < ApplicationRecord
  has_and_belongs_to_many :participations
  has_many :observations
end