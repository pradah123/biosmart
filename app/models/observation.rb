class Observation < ApplicationRecord
  scope :recent, -> { order observed_at: :desc }
  scope :has_images, -> { where 'observation_images_count > ?', 0 }
  scope :has_scientific_name, -> { where.not scientific_name: @@filtered_scientific_names }
  scope :has_accepted_name, -> { where.not accepted_name: @@filtered_scientific_names }
  scope :from_observation_org, -> { joins(:data_source).where(data_sources: { name: 'observation.org' }) }
  scope :ignore_species_code, -> { where('accepted_name != lower(accepted_name)') }
  scope :has_creator_id, -> { where.not creator_id: nil }
  scope :without_creator_name, -> { where creator_name: nil }
  scope :search, -> (q) { where 'search_text LIKE ?', "%#{q.downcase}%" }

  #
  # an observation may belong to multiple regions, participations, or contests
  #

  has_and_belongs_to_many :regions
  has_and_belongs_to_many :participations
  has_and_belongs_to_many :contests
  belongs_to :data_source
  has_many :observation_images

  # after_save :update_search_text, :update_address, :add_to_regions_and_contests
  after_save :update_search_text, :add_to_regions_and_contests

  validates :unique_id, presence: true
  validates :lat, presence: true
  validates :lng, presence: true    
  validates :observed_at, presence: true
    
  @@filtered_scientific_names = [nil, 'homo sapiens', 'Homo Sapiens', 'Homo sapiens']
  @@nobservations_per_page = 33




  def update_search_text
    update_column :search_text, "#{scientific_name} #{common_name} #{accepted_name} #{creator_name}".downcase
  end

  def update_address
    #
    # get the text location for this lat lng, via the google geocode api.
    # currently not used, was intended to show this data in the observations cards.
    #

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

  #
  #  new method of adding observations to regions, participations, and contests,
  #  in the case where we need to be continously fetching data for all regions.
  #

  def add_to_regions_and_contests
    added = false
    inside = false
    geokit_point = Geokit::LatLng.new lat, lng

    # 
    # remove any existing relations with regions, participations
    # and contests
    #

    regions.each do |region|
      region.get_geokit_polygons.each do |polygon|
        if polygon.contains?(geokit_point) 
          inside = true
          break
        end
      end
      if inside==false         
        region.observations.where(id: id).delete_all
      end    
    end

    participations.each do |participation|
      unless can_participate_in(participation)
        participation.observations.where(observation_id: id).delete_all
        participation.contest.observations.where(observation_id: id).delete_all
      end
    end  

    #
    # find the regions which the observation is included in
    #
    
    Region.all.each do |region|
      region.get_geokit_polygons.each do |polygon|
        if polygon.contains?(geokit_point)

          #
          # inside one of the region's polygons
          #
          region.add_and_compute_statistics self
          # Observation.add_observation_to_page_caches self, region
         
          region.participations.each do |participation|
            if can_participate_in(participation)
              #
              # this observation is in this contest in time and space
              # add references for this observation to contest, participation, and region
              #              
              participation.contest.add_and_compute_statistics self
              participation.add_and_compute_statistics self
              # Observation.add_observation_to_page_caches self, participation              
            end  
          end

          break
        end
      end
    end

    added
  end

  def can_participate_in participation
    # from one of the requested data sources
    return false unless participation.data_sources.include?(data_source) 

    # observed in the period of the contest
    return false unless observed_at>=participation.starts_at && observed_at<participation.ends_at 
          
    # submitted in the allowed period  
    return false unless created_at>=participation.starts_at && created_at<participation.last_submission_accepted_at 

    true
  end  




  def self.get_search_results region_id, contest_id, q
    #
    # returns observations in a region and/or contest which match
    # a keyword search for q
    #
    # one or both of region and contest may be nil
    #

    if region_id && contest_id
      obj = Participation.where contest_id: contest_id, region_id: region_id
    elsif region_id
      obj = Region.where id: region_id
    elsif contest_id
      obj = Contest.where id: contest_id
    else
      obj = nil
    end

    q = q.blank? ? '' : q.strip.downcase

    if obj.nil?
      observations = q.blank? ? Observation.all : Observation.all.search(q).recent
    else 
      observations = q.blank? ? obj.first.observations : obj.first.observations.search(q)
    end

    nobservations_all = observations.count
    observations = observations.has_images.has_scientific_name.recent
    nobservations = observations.count
    nobservations_excluded = nobservations_all - nobservations

    { observations: observations, nobservations: nobservations, nobservations_excluded: nobservations_excluded }
  end



  #
  #  code used to create observations in the old code
  #

  def self.store observations
    nupdates = 0
    nupdates_no_change = 0
    nupdates_failed = 0
    nfields_updated = 0
    ncreates = 0
    ncreates_failed = 0

    observations.each do |params|
      obs = Observation.find_by_unique_id params[:unique_id]
      image_urls = (params.delete :image_urls) || []
      
      if obs.nil? 
        obs = Observation.new params
        if obs.save
          ncreates += 1
          image_urls.each do |url|
            ObservationImage.create! observation_id: obs.id, url: url
          end
        else
          ncreates_failed += 1          
          Rails.logger.info "\n\n\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
          Rails.logger.info "Create failed on observation"
          Rails.logger.info obs.inspect
          Rails.logger.info params.inspect
          Rails.logger.info "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n\n"
        end

      else
        obs.attributes = params
        if obs.changed.empty?
          nupdates_no_change += 1
        else
          nupdates += 1  
          nfields_updated += obs.changed.length
          if obs.save

            current_image_urls = obs.observation_images.pluck :url
            if current_image_urls-image_urls!=[] 
              # if the images given are not the same as the ones present, delete the old
              # ones and remake them
              obs.observation_images.delete_all
              image_urls.each do |url|
                ObservationImage.create! observation_id: obs.id, url: url
              end
            end  

          else  
            nupdates_failed +=1 
            Rails.logger.info "\n\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
            Rails.logger.info "Update failed on observation #{obs.id}"
            Rails.logger.info obs.inspect
            Rails.logger.info params.inspect
            Rails.logger.info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n\n"
          end
        end
      end

    end

  end





  #
  # caching of observations data per page, to speed up page loading
  # no longer used.
  #

  @@page_cache = {}
  @@page_cache_last_update = {}

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
        @@page_cache[key] = Observation.all.has_images.recent.first @@nobservations_per_page
      else
        @@page_cache[key] = obj.observations.has_images.recent.first @@nobservations_per_page
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
