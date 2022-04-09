class Contest < ApplicationRecord
  scope :ordered_by_creation, -> { order created_at: :desc }
  scope :ordered_by_starts_at, -> { order starts_at: :desc }
  scope :in_progress, -> { where 'starts_at < ? AND ends_at > ?', Time.now, Time.now }
  scope :upcoming, -> { where 'starts_at > ?', Time.now } 
  scope :past, -> { where 'ends_at < ?', Time.now } 

  belongs_to :user, optional: true  
  has_many :participations
  has_many :regions, through: :participations
  has_and_belongs_to_many :observations

  enum status: [:online, :offline, :deleted, :completed]

  def add_observation obs, time_check=true
    Rails.logger.info "assigning to contest #{id}, obs #{obs.id}"

    added = false
    if time_check==false || (obs.observed_at>=starts_at && obs.observed_at<ends_at) # in the period of the contestß
      participations.in_competition.each do |participation|
        if participation.data_sources.include?(obs.data_source) # from one of the requested data sources

          polygons = participation.region.get_geokit_polygons

          polygons.each do |polygon|
            if polygon.contains?(Geokit::LatLng.new obs.lat, obs.lng) # inside one of the region's polygons
              
              #
              # this observation is in this contest
              # add references for this observation to contest, participation, and region
              #
              observations << obs      
              participation.observations << obs
              participation.region.observations << obs

              added = true
              break
            end
          end

        end    
      end
    end
    added
  end

  def remove_observation obs
    observations.where(observation_id: obs.id).delete_all
    participations.in_competition.each do |participation|
      participation.observations.where(observation_id: obs.id).delete_all
      participation.region.observations.where(observation_id: obs.id).delete_all
    end  
  end  

end  
