class Observation < ApplicationRecord
  scope :recent, -> { order created_at: :desc }

  has_and_belongs_to_many :regions
  has_and_belongs_to_many :participations
  has_and_belongs_to_many :contests
  belongs_to :data_source

  after_save :assign_to_regions

  def assign_to_regions

    # add this observation to a region if it lies within the region

    Region.all.each do |r|
      regions << r if r.region_contains(lat, lng)
    end

    # if the observed time falls within a contest, add it to the participation object

    Participations.where(observed_at: (contest.starts_at..contest.ends_at)).each do |p|
      p.observations << self if p.data_sources.contains?(data_source)
    end
  end
    
end