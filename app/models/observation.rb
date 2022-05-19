class Observation < ApplicationRecord
  scope :recent, -> { order observed_at: :desc }
  scope :has_image, -> { where 'observation_images_count > ?', 0 }
  scope :has_scientific_name, -> { where.not scientific_name: @@filtered_scientific_names }
  scope :has_accepted_name, -> { where.not accepted_name: @@filtered_scientific_names }
  scope :from_observation_org, -> { joins(:data_source).where(data_sources: { name: 'observation.org' }) }
  scope :ignore_species_code, -> { where('accepted_name != lower(accepted_name)') }
  scope :has_creator_id, -> { where.not creator_id: nil }
  scope :without_creator_name, -> { where creator_name: nil }
  scope :search, -> (q) { where 'search_text LIKE ?', "%#{q.downcase}%" }

  has_and_belongs_to_many :regions
  has_and_belongs_to_many :participations
  has_and_belongs_to_many :contests
  belongs_to :data_source
  has_many :observation_images

  after_create :assign_to_contests
  after_update :update_to_contests, if: :saved_change_to_lat || :saved_change_to_lng
  after_save :update_search_text, :update_address

  validates :unique_id, presence: true  
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
    
  def update_search_text
    update_column :search_text, "#{scientific_name} #{common_name} #{accepted_name} #{creator_name}".downcase
  end

  def update_address
    google_api_key = "AIzaSyBFT4VgTIfuHfrL1YYAdMIUEusxzx9jxAQ"
    url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=#{self.lat},#{self.lng}&key=#{google_api_key}"
    begin
      response = HTTParty.get url
      response_json = JSON.parse response.body
Rails.logger.info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
Rails.logger.info response_json
Rails.logger.info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      address = ""#response_json['results']
      update_column :address, address
    rescue => e
      Rails.logger.error "google gecode api failed for lat,lng = #{lat},#{lng}" 
    end
  end  


  @@page_cache = {}
  @@page_cache_last_update = {}
  @@filtered_scientific_names = [nil, 'homo sapiens', 'Homo Sapiens', 'Homo sapiens']
  @@nobservations_per_page = 33

  def self.add_observation_to_page_caches obs, contest, region, participation

=begin
    if top_page_cache.length==0
      @@top_page_cache = 
    end
    if can_add_to_cache(obs)==false
      @@top_page_cache.prepend obs
      @@top_page_cache = @@top_page_cache.shift unless @@top_page_cache.count>@@nobservations_per_page
    end
=end    
  end

  def self.get_observations obj=nil
    key = get_key obj
    now = Time.now
    if @@page_cache[key].blank? || (@@page_cache_last_update[key]>now+30.minutes)
      if obj.nil?
        @@page_cache[key] = Observation.all.has_image.has_scientific_name.recent.first @@nobservations_per_page
      else
        @@page_cache[key] = obj.observations.has_image.has_scientific_name.recent.first @@nobservations_per_page
      end
      @@page_cache_last_update[key] = now
    end
    @@page_cache[key]
  end

  def self.get_key obj
    obj.nil? ? 'top' : "#{ obj.class.name[0] }#{ obj.id }"
  end

  def self.can_add_to_cache obs
    return false if @@filtered_scientific_names.include?(observation.scientific_name)
    return false if obs.observation_images_count==0
    true
  end



  def add_to_regions_and_contests
    added = false

    geokit_point = Geokit::LatLng.new lat, lng

    Region.all.each do |region|
      region.get_geokit_polygons.each do |polygon|
        if polygon.contains?(geokit_point)

          # inside one of the region's polygons
          region.add_and_compute_statistics self
          Observation.add_observation_to_page_caches self, region
          added = true

          region.participations.in_competition.each do |participation|
            # from one of the requested data sources
            if participation.data_sources.include?(data_source) 

              # observed in the period of the contest
              if observed_at>=participation.starts_at && observed_at<participation.ends_at 
          
                # submitted in the allowed period  
                if created_at>=participation.starts_at && created_at<participation.last_submission_accepted_at 
          
                  #
                  # this observation is in this contest in time and space
                  # add references for this observation to contest, participation, and region
                  #

                  participation.contest.add_and_compute_statistics self
                  participation.add_and_compute_statistics self
                  Observation.add_observation_to_page_caches self, participation
                
                end
              end
            end  
          end

          break if added==true
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
      field :creator_name
      field :unique_id
      field :scientific_name
      field :observed_at
      field :lat
      field :lng
      field :created_at      
    end
    edit do 
      field :data_source
      field :creator_name
      field :unique_id
      field :common_name
      field :accepted_name
      field :scientific_name
      field :observed_at
      field :lat
      field :lng
    end
    show do
      field :id
      field :creator_name
      field :unique_id
      field :common_name
      field :accepted_name
      field :scientific_name
      field :observed_at
      field :lat
      field :lng
      field :created_at
    end
  end 

end
