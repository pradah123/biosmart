class Participation < ApplicationRecord
  belongs_to :user
  belongs_to :region
  belongs_to :contest
  has_and_belongs_to_many :data_sources
  has_and_belongs_to_many :observations

  enum status: [:submitted, :accepted, :refused, :removed_by_admin, :removed_by_region]

  after_save :assign_observations

  def assign_observations

    # the observations in a participation are the subset of observations in the region which are:
    #   1. in the time period of the contest, and 
    #   2. are from the data sources assigned to this participation

    observations.clear
    ids = data_sources.map { |ds| ds.observations.pluck :id }.flatten.uniq # avoid join query
    observations << region.observations.where(id: ids, observed_at: (contest.starts_at..contest.ends_at))
  end
    
end