class Observation < ApplicationRecord
  scope :recent, -> { order observed_at: :desc }
  scope :has_image, -> { where 'observation_images_count > ?', 0 }
  scope :has_scientific_name, -> { where.not scientific_name: [nil, 'TBD', 'homo sapiens', 'Homo Sapiens', 'Homo sapiens'] }
  scope :from_observation_org, -> { joins(:data_source).where(data_sources: { name: 'observation.org' }) }
  scope :has_creator_id, -> { where.not creator_id: nil }
  scope :without_creator_name, -> { where creator_name: nil }

  has_and_belongs_to_many :regions
  has_and_belongs_to_many :participations
  has_and_belongs_to_many :contests
  belongs_to :data_source
  has_many :observation_images

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
