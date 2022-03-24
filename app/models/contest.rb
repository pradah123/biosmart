class Contest < ApplicationRecord
  belongs_to :user  
  has_many :participations
  has_many :regions, through: :participations

  enum status: [:online, :offline, :deleted, :completed]  
end