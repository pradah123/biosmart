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
  after_save :update_search_text, :update_to_regions_and_contests

  validates :unique_id, presence: true
  validates :lat, presence: true
  validates :lng, presence: true    
  validates :observed_at, presence: true
    
  @@filtered_scientific_names = [nil, 'homo sapiens', 'Homo Sapiens', 'Homo sapiens']
  @@nobservations_per_page = 18




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

  ### Method for adding an observation to matching regions, participations and contests
  def add_to_regions_and_contests(geokit_point, data_source_id=nil, participant_id=nil)
    Region.all.each do |region|
      region.get_geokit_polygons.each do |polygon|

        if polygon.contains?(geokit_point)
          ## Add observation to region only if it's not already added
          obs = find_observation(region_id: region.id,
                                 observation_id: self.id,
                                 data_source_id: data_source_id)

          if obs.blank?
            begin
              insert_sql = get_observations_regions_insert_statement(region_id: region.id,
                                  observation_id: self.id, data_source_id: data_source_id)
              ActiveRecord::Base.connection.execute insert_sql
            rescue => error
              Delayed::Worker.logger.info("ERROR for region_id: #{region.id}, observation_id: #{id}, data_source_id: #{data_source_id} #{error.message}")
            end  
          end

          participations = (participant_id.present? ? region.participations.where(id: participant_id) : region.participations)
          participations.each do |participation|
            if can_participate_in(participation)
              #
              # this observation is in this contest in time and space
              # add references for this observation to contest, participation only if
              # doesn't exist already
              if !participation.contest.observations.exists?(self.id)
                participation.contest.observations << self
              end
              if !participation.observations.exists?(self.id)
                participation.observations << self
              end
            end
          end
          break
        end
      end
    end
  end

  #
  #  Method of updating observations to regions, participations, and contests,
  #  in the case where we need to be continously fetching data for all regions.
  #
  def update_to_regions_and_contests(data_source_id: nil, participant_id: nil)
    geokit_point = Geokit::LatLng.new lat, lng
    data_source_id = data_source_id.present? ? data_source_id : data_source.id

    # 
    # remove any existing relations with regions, participations
    # and contests only if observation exists in the system
    #

    ## Commenting following code as of now because currently if observation doesn't belong to any region
    ## anymore, it is getting deleted but it's not checking whether it belongs to any other
    ## region or not. Will fix in Trello 362
    # regions.each do |region|
    #   inside = false
    #   region.get_geokit_polygons.each do |polygon|
    #     if polygon.contains?(geokit_point)
    #       inside = true
    #       break
    #     end
    #   end
    #   if inside==false
    #     Delayed::Worker.logger.info("Deleting observation id: #{id} with unique id : #{unique_id}
    #       for region - #{region.name}, #{region.id}")
    #     region.observations.where(id: id).delete_all
    #   end
    # end

    ## Commenting following code as of now because currently if observation doesn't belong
    ## to any participation anymore, it is not getting deleted
    ## but it's getting deleted for gbif as we don't add gbif in participation
    ## Will fix in Trello 362
    # participations.each do |participation|
    #   unless can_participate_in(participation)
    #     Delayed::Worker.logger.info("Deleting observation id: #{id} with unique id : #{unique_id}
    #       for participation - #{participation.id}")
    #     participation.observations.where(id: id).delete_all
    #     participation.contest.observations.where(id: id).delete_all
    #   end
    # end

    ## Add observation to regions and contests
    self.add_to_regions_and_contests geokit_point, data_source_id, participant_id

  end

  def can_participate_in participation
    # from one of the requested data sources
    return false unless participation.data_sources.include?(data_source) 

    # Check if competition is on going or not
    return false unless participation.is_active?

    # observed in the period of the contest
    return false unless observed_at>=participation.starts_at && observed_at<participation.ends_at 
          
    # submitted in the allowed period  
    return false unless created_at>=participation.starts_at && created_at<participation.last_submission_accepted_at 

    true
  end  

  ## This will return observations associated with observations_regions for given region_id, data source(gbif or no gbif),  and date range
  def self.get_observations_for_region(region_id: , start_dt: nil, end_dt: nil, include_gbif: false)
    obs = Observation.joins("JOIN OBSERVATIONS_REGIONS obsr ON obsr.observation_id = observations.id").
                            where(["obsr.region_id = ?", region_id])
    data_source_clause = (include_gbif == true ? "obsr.data_source_id = ?" : "obsr.data_source_id != ?")
    obs = obs.where([data_source_clause, DataSource.find_by_name('gbif').id])

    if start_dt.present? && end_dt.present?
      return obs.where("observed_at BETWEEN ? and ?", start_dt ,end_dt)
    else
      return obs
    end
  end


  # This will return an Observation associated with OBSERVATIONS_REGIONS for given region_id, observation_id and data source
  def find_observation(region_id: , observation_id: nil, data_source_id:)
    obs = Observation.joins(" JOIN OBSERVATIONS_REGIONS obsr ON obsr.observation_id = observations.id").
                            where(["obsr.observation_id = ?", observation_id]).
                            where(["obsr.region_id = ?", region_id]).
                            where(["obsr.data_source_id = ?", data_source_id])

    return obs
  end

  # This will return insert statement for OBSERVATIONS_REGIONS table
  def get_observations_regions_insert_statement(region_id: , observation_id: , data_source_id:)
    insert_sql = "INSERT INTO OBSERVATIONS_REGIONS(region_id, observation_id, data_source_id,
                                                  created_at, updated_at)
                  VALUES(#{region_id}, #{observation_id}, #{data_source_id},
                        '#{Time.now}', '#{Time.now}')"
    return insert_sql
  end

  def self.get_search_results region_id, contest_id, q, nstart, nend
    #
    # returns observations in a region and/or contest which match
    # a keyword search for q and with limit as per given nstart to nend params
    #
    # one or both of region and contest may be nil
    #
    nstart = nstart || 0
    nend   = nend   || 18
    offset = nstart
    limit  = nend - nstart

    start_dt = end_dt = nil
    if region_id && contest_id
      obj = Participation.where contest_id: contest_id, region_id: region_id
    elsif region_id
      obj = Region.where id: region_id
      (start_dt, end_dt) = obj.first.get_date_range_for_report()
    elsif contest_id
      obj = Contest.where id: contest_id
    else
      obj = nil
    end

    q = q.blank? ? '' : q.strip.downcase

    if obj.nil?
      observations = q.blank? ? Observation.all : Observation.all.search(q).recent
    else 
      if (start_dt.present? && end_dt.present?)
        obs = get_observations_for_region(region_id:    obj.first.id,
                                          start_dt:     start_dt,
                                          end_dt:       end_dt,
                                          include_gbif: true)
        observations = q.blank? ? obs : obs.search(q)
      else
        observations = q.blank? ? obj.first.observations : obj.first.observations.search(q)
      end
    end
    nobservations_all = observations.count
    nobservations_with_images = observations.has_images.has_scientific_name.recent.count
    nobservations_excluded = nobservations_all - nobservations_with_images

    observations = observations.has_images.has_scientific_name.recent.offset(offset).limit(limit)

    { observations: observations, nobservations: nobservations_all, nobservations_excluded: nobservations_excluded }
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

  def observed_at_utc
    return "#{ observed_at.strftime '%Y-%m-%d %H:%M' } UTC"
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
