class Participation < ApplicationRecord
  include CountableStatistics

  #
  # each region which participates in a contest must have
  # a participation object
  #

  scope :in_competition, -> { where status: Participation.statuses[:accepted] }
  scope :ordered_by_observations_count, -> { order observations_count: :desc }

  belongs_to :user, optional: true
  belongs_to :region
  belongs_to :contest
  has_and_belongs_to_many :data_sources
  has_and_belongs_to_many :observations
  
  after_save :set_start_and_end_times

  enum status: [:submitted, :accepted, :refused, :removed_by_admin, :removed_by_region] 

  def set_start_and_end_times
    #
    # contest model start and end datetimes are not utc- they refer to the time in the local time of each region. 
    # the actual start and end are those datetimes in the timezone of the region, in utc.
    #

    offset = region.timezone_offset_mins.nil? ? 0 : (region.timezone_offset_mins.abs*60)
    if region.timezone_offset_mins<0
      update_column :starts_at, (contest.starts_at + offset)
      update_column :ends_at, (contest.ends_at + offset)
      update_column :last_submission_accepted_at, (contest.last_submission_accepted_at + offset)
    else
      update_column :starts_at, (contest.starts_at - offset)
      update_column :ends_at, (contest.ends_at - offset)
      update_column :last_submission_accepted_at, (contest.last_submission_accepted_at - offset)
    end       

    Rails.logger.info "\n\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> timings debug"
    Rails.logger.info "contest starts at #{contest.starts_at.strftime '%Y/%m/%d %H:%M'} in each region"
    Rails.logger.info "region timezone difference #{region.timezone_offset_mins} minutes = #{region.timezone_offset_mins/60} hours"
    Rails.logger.info "offset in seconds = #{offset}"
    Rails.logger.info "participation starts at #{starts_at}"
    Rails.logger.info "\n\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> timings debug"

    contest.set_utc_start_and_end_times
  end

  def is_active?
    return last_submission_accepted_at.present? && last_submission_accepted_at >= Time.now.utc
  end

  rails_admin do
    list do
      field :id
      field :region          
      field :contest
      field :status
      field :data_sources
      field :created_at     
    end
    edit do
      field :region          
      field :contest
      field :status
      field :data_sources
    end
    show do
      field :id
      field :region          
      field :contest
      field :status
      field :data_sources
      field :created_at     
    end    
  end

end
