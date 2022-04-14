class Participation < ApplicationRecord
  include CountableStatistics
  scope :in_competition, -> { where status: Participation.statuses[:accepted] }
  belongs_to :user
  belongs_to :region
  belongs_to :contest
  has_and_belongs_to_many :data_sources
  has_and_belongs_to_many :observations
  
  after_save :set_utc_start_and_end_times

  enum status: [:submitted, :accepted, :refused, :removed_by_admin, :removed_by_region] 

  def set_utc_start_and_end_times timezone_mins=0
    #
    # contest start and end datetimes are in utc. 
    # actual start and end are those datetimes in the timezone of the region
    #
    #update_attribute! utc_starts_at: (contest.starts_at - timezone_mins.minutes)
    #update_attribute! utc_ends_at: (contest.ends_at - timezone_mins.minutes)
    #contest.set_utc_start_and_end_times
  end

end