class Observation < ApplicationRecord
  scope :recent, -> { order created_at: :desc }

  has_and_belongs_to_many :regions
  has_and_belongs_to_many :participations
  has_and_belongs_to_many :contests
  belongs_to :data_source

  after_create :assign_to_contests
  after_update :update_to_contests, if: :saved_change_to_lat || :saved_change_to_lng

  validates :unique_id, presence: true
  validates :scientific_name, presence: true
  validates :lat, presence: true
  validates :lng, presence: true    
  validates :observed_at, presence: true
 
  def assign_to_contests
    Contest.in_progress.each { |c| c.add_observation self }
  end

  def update_to_contests
    Contest.in_progress.each { |c| c.remove_observation self }
    Contest.in_progress.each { |c| added = c.add_observation self }
  end
    
end