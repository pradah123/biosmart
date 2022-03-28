class Contest < ApplicationRecord
  scope :ordered_by_creation, -> { order created_at: :desc }
  scope :ordered_by_starts_at, -> { order starts_at: :desc }
  scope :upcoming, -> { where 'starts_at > ?', Time.now } 
  scope :past, -> { where 'ends_at < ?', Time.now } 

  belongs_to :user, optional: true  
  has_many :participations
  has_many :regions, through: :participations
  has_and_belongs_to_many :observations

  after_save :assign_observations, if: :saved_change_to_starts_at || :saved_change_to_ends_at

  enum status: [:online, :offline, :deleted, :completed]

  def assign_observations
    
    # observations in a contest are the aggregate observations from 
    # all accepted participations

    observations.clear
   
    participations.where(status: Participation.statuses[:accepted]).each do |p|
      p.assign_observations # if the contest dates change, the participating observations also change
      observations << p.observations
    end

  end

end