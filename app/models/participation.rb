class Participation < ApplicationRecord
  belongs_to :region
  belongs_to :contest
  enum status: [:submitted, :accepted, :refused, :removed_by_admin, :removed_by_region]
end