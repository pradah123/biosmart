class Contest < ApplicationRecord
  include CountableStatistics
    
  scope :ordered_by_creation, -> { order created_at: :desc }
  scope :ordered_by_starts_at, -> { order starts_at: :desc }
  scope :in_progress, -> { where 'contests.utc_starts_at < ? AND contests.last_submission_accepted_at > ?', Time.now, Time.now }
  scope :upcoming, -> { where 'utc_starts_at > ?', Time.now } 
  scope :past, -> { where 'contests.last_submission_accepted_at < ?', Time.now }
  scope :online, -> { where status: Contest.statuses[:online] }

  belongs_to :user, optional: true
  has_many :participations, dependent: :delete_all
  has_many :regions, through: :participations
  has_and_belongs_to_many :observations

  after_save :set_last_submission_accepted_at, :set_slug

  enum status: [:online, :offline, :deleted, :completed]
  enum rank_regions_by: [:recent]

  def set_utc_start_and_end_times
    if participations.count>0
      update_column :utc_starts_at, participations.pluck(:starts_at).compact.min
      update_column :utc_ends_at, participations.pluck(:ends_at).compact.max
    end
  end

  def set_last_submission_accepted_at
    update_column :last_submission_accepted_at, ends_at if last_submission_accepted_at.nil?
  end





  def set_slug
    if slug.nil?
      slug = title.nil? ? '' : title.downcase.gsub(/[^[:word:]\s]/, '').gsub(/ /, '-')
      update_column :slug, slug
    end  
  end
    
  def get_path
    "/contest/#{slug}"
  end

  def get_region_contest_path region
    region.get_region_contest_path self
  end  

  def get_region_polygons
    regions.map { |r| JSON.parse r.raw_polygon_json }.flatten.map { |p| p.to_hash }
  end  



  def add_observation obs
    added = false

    participations.in_competition.each do |participation|
      # from one of the requested data sources
      if participation.data_sources.include?(obs.data_source) 

        # observed in the period of the contest
        if obs.observed_at>=participation.starts_at && obs.observed_at<participation.ends_at 
          
          # submitted in the allowed period  
          if obs.created_at>=participation.starts_at && obs.created_at<participation.last_submission_accepted_at 
          
            polygons = participation.region.get_geokit_polygons

            polygons.each do |polygon|
              if polygon.contains?(Geokit::LatLng.new obs.lat, obs.lng) # inside one of the region's polygons
              
                #
                # this observation is in this contest in time and space
                # add references for this observation to contest, participation, and region
                #

                add_and_compute_statistics obs
                participation.add_and_compute_statistics obs
                participation.region.add_and_compute_statistics obs
                # Observation.add_observation_to_page_caches obs, self, region, participation

                added = true
                break
              end
            end

          end  
        end    
      end
    end

    added
  end

  def remove_observation obs
    observations.where(id: obs.id).delete_all
    participations.in_competition.each do |participation|
      participation.observations.where(id: obs.id).delete_all
      participation.region.observations.where(id: obs.id).delete_all
    end  
  end  





  rails_admin do
    list do
      field :id
      field :title
      field :user
      field :starts_at
      field :ends_at
      field :last_submission_accepted_at    
      field :created_at              
    end
    edit do
      field :user
      field :status
      field :title
      field :slug
      field :description
      field :starts_at
      field :ends_at
      field :last_submission_accepted_at   
    end
    show do
      field :id      
      field :user
      field :status
      field :title
      field :slug
      field :description
      field :starts_at
      field :ends_at
      field :last_submission_accepted_at 
      field :utc_starts_at
      field :utc_ends_at
      field :created_at  
    end
  end  

end  
