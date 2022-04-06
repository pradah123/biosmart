class Participation < ApplicationRecord
  scope :in_competition, -> { where status: Participation.statuses[:accepted] }
  belongs_to :user
  belongs_to :region
  belongs_to :contest
  has_and_belongs_to_many :data_sources
  has_and_belongs_to_many :observations
  enum status: [:submitted, :accepted, :refused, :removed_by_admin, :removed_by_region] 
end