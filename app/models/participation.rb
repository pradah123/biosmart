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


  ### Return participation specific data
  def format_data(include_top_species=false, include_top_people=false,
                  include_recent_sightings=false, offset=0, limit=24)
    polygon_geojson = region.get_polygon_json

    data = {
      ### Region specific data
      region_name:    region.name,
      description:    region.description,
      logo_image_url: region.logo_image_url,
      header_image:   region.header_image,
      polygon:        polygon_geojson,
      lat:            region.lat,
      lng:            region.lng,

      ## Participation data i.e. Region's data related to given contest
      observations_count:     observations_count,
      identifications_count:  identifications_count,
      species_count:          species_count,
      people_count:           people_count,
      bioscore:               bioscore,
      physical_health_score:  physical_health_score,
      mental_health_score:    mental_health_score
    }
    ## Include top species data related to participation
    if include_top_species == true
      data['top_species'] = get_top_species(10).map { | species |
        {
          name:  species[0],
          count: species[1]
        }}
    end
    ## Include top people data related to participation
    if include_top_people == true
      data['top_observers'] = get_top_people(10).map { | observers |
          {
            name:  observers[0],
            observations_count: observers[1]
          }}
    end
    ## Include the recent sightings data only if recent_sightings query param value is 'true'
    if include_recent_sightings == true
      data['recent_sightings'] =  observations.has_scientific_name.recent.offset(offset).limit(limit).map { |obs| {
        scientific_name:  obs.scientific_name,
        common_name:      obs.common_name,
        creator_name:     (obs.creator_name.nil? ? '' : obs.creator_name),
        observed_at:      obs.observed_at_utc,
        image_urls:       obs.observation_images.pluck(:url),
        lat:              obs.lat,
        lng:              obs.lng
      }}
    end

    return data
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
