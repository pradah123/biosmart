class Observation < ApplicationRecord
  scope :recent, -> { order created_at: :desc }

  has_and_belongs_to_many :regions
  has_and_belongs_to_many :participations
  has_and_belongs_to_many :contests
  belongs_to :data_source

  after_create :assign_to_contests
  after_save :update_to_contests, if: :saved_change_to_lat || :saved_change_to_lng

  def assign_to_contests
    Contest.in_progress.each { |c| c.add_observation self }
  end

  def update_to_contests
    Contest.in_progress.each { |c| c.remove_observation self }
    Contest.in_progress.each { |c| added = c.add_observation self }
  end
    
end