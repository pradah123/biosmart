require './services/region'
require './lib/common/utils'

module Api::V1
  class RegionController < ApiController
    def create
      region = params[:region].permit!
      contest_ids = params[:contest] || []

      if !region['name'] || !region['description'] || !region['logo_image_url']
        raise ApiFail.new("Must provide 'name', 'description' and 'logo_image_url' to add a new region")
      end

      region_obj = Region.find_by_id region['id']
      if !region_obj.nil?
        raise ApiFail.new("Region with id '#{region['id']}' already exists.")
      else
        region_obj = Region.new region
        success_message = ''
        if region_obj.save
          success_message = 'Region has been added successfully. '
          contest_ids = contest_ids.reject(&:empty?).map(&:to_i)
          error_message = ''
          contest_ids.each do |contest_id|
            contest_obj = Contest.in_progress.find_by_id(contest_id)
            if contest_obj.present?
              region_obj.add_to_contest(contest_id: contest_id)
              success_message += "Region has been added to contest '#{contest_id}'. "
            else
              error_message += "No ongoing contest found for contest id '#{contest_id}', couldn't add region to it."
            end
          end
          r = { 'success_message': success_message, 'warning_message': error_message }
          render_success r
          return
        else
          raise ApiFail.new("Error occurred while creating the region.")
        end
      end
    end

    def update
      region = params[:region].permit!
      contest_ids = params[:contest] || []
      id = region['id'] || params[:id] || ''
      region_obj = Region.find_by_id id
      if region_obj.nil?
        raise ApiFail.new("Region with '#{id}' does not exist.")
      end
      raise ApiFail.new("Must provide 'contest'") if !region['id'] && params[:id] && contest_ids.blank?

      region_obj.attributes = region
      success_message = ''
      if region_obj.save
        success_message = 'Region has been updated successfully. '
        contest_ids = contest_ids.reject(&:empty?).map(&:to_i)
        existing_contests = region_obj.contests
                                      .where("contests.utc_starts_at <  '#{Time.now}' AND
                                          contests.last_submission_accepted_at > '#{Time.now}'")
                                      .pluck(:id)
        contests_to_add = contest_ids - existing_contests
        contests_to_remove = existing_contests - contest_ids

        error_message = ''
        contests_to_add.each do |contest_id|
          contest_obj = Contest.in_progress.find_by_id(contest_id)
          if contest_obj.present?
            region_obj.add_to_contest(contest_id: contest_id)
            success_message += "Region has been added to contest '#{contest_id}'. "
          else
            error_message += "No ongoing contest found for contest id '#{contest_id}', couldn't add region to it."
          end
        end
        contests_to_remove.each do |contest_id|
          region_obj.participations.where(contest_id: contest_id).delete_all
          success_message += "Region has been removed from contest '#{contest_id}'. "
        end
        r = { 'success_message': success_message, 'warning_message': error_message }
        render_success r
      else
        raise ApiFail.new("Error occurred while updating the region '#{id}'")
      end
      return
    end

    def search
      search_params = params.to_unsafe_h.symbolize_keys
      Service::Region::Fetch.call(search_params) do |result|
        result.success do |regions|
          @regions = regions
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def show
      show_params = params.to_unsafe_h.symbolize_keys
      Service::Region::Show.call(show_params) do |result|
        result.success do |region|
          region_hash = RegionSerializer.new(region).serializable_hash[:data][:attributes]
          region_scores = region.get_region_scores
          region_hash.merge!(region_scores)
          contest_ids = region.contests.in_progress.pluck(:id)
          contest_ids = contest_ids.map(&:to_s)
          region_hash[:contest] = contest_ids
          render json: region_hash
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def search_by_species
      search_params = params.to_unsafe_h.symbolize_keys
      Service::Region::SearchBySpecies.call(search_params) do |result|
        result.success do |searched_regions|
          render json: searched_regions
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def sightings_count
      search_params = params.to_unsafe_h.symbolize_keys
      Service::Region::Sightings.call(search_params) do |result|
        result.success do |sightings_count|
          render json: sightings_count
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def species_image
      r = Region.find_by_id params[:region_id]
      raise ApiFail.new("Invalid region_id provided.") if r.blank?
      raise ApiFail.new("Must provide search_text.") unless params[:search_text]

      search_text = params[:search_text]
      raise ApiFail.new("Invalid search_text provided.") if search_text.blank?
      species_image = RegionsObservationsMatview.get_species_image(region_id: r.id,
                                                                   search_text: search_text)
      render json: species_image
    end

    def polygons_old
      data = {}

      DataSource.all.each do |ds|
        polygons = []
        Contest.in_progress.each do |c|
          c.participations.in_competition.each do |p|
            polygons.push JSON.parse(p.region.raw_polygon_json) if p.data_sources.include?(ds)
          end
        end    
        data[ds.name] = polygons
      end

      render json: data
    end

    def polygons
      data = {}

      regions = []
      Region.all.each do |r|
        json = { name: r.name }
        json[:data_sources] = r.participations.map { |p| p.data_sources }.flatten.uniq.map { |ds| ds.name }
        begin
          json[:polygons] = JSON.parse r.raw_polygon_json unless r.raw_polygon_json.nil?
        rescue
        end  
        regions.push json
      end
      data[:regions] = regions

      render json: data
    end  

    def data
      r = Region.find_by_id params[:region_id]
      c = Contest.find_by_id params[:contest_id]

      error_message = nil
      error_message = { status: 'error', message: "no region found with that id" } if r.nil?
      error_message = { status: 'error', message: "no contest found with that id" } if c.nil?
      unless error_message.nil?
        render json: error_message
        return
      end  

      p = r.participations.find_by_contest_id c.id
      if p.nil?
        render json: { status: 'error', message: "region not a contestant in this contest" }
        return
      end  
          
      data = { 
        title: r.name,
        observations: p.observations_count,
        species: p.species_count,
        identifications: p.identifications_count,
        people: p.people_count
      }

      render json: data
    end

    # This function returns polygon(square) of side length 1 km for given coordinates.
    # Used for API api/v1/region/polygon/from_coordinates
    # Required parameters are lat and lng
    # Optional parameters are polygon_side_length (if not passed considered as 1 km),
    #                         polygon_format (valid value is wkt, for anything else it will return
    #                                         polygon in geojson format)
    def generate_polygon
      lat = params[:lat]
      lng = params[:lng]
      polygon_side_length = params[:polygon_side_length] || 1
      polygon_format = params[:polygon_format]

      if !lat || !lng
        raise ApiFail.new("Must provide 'lat' and 'lng'")
      end
      polygon_radius = Utils.get_polygon_radius(polygon_side_length.to_f)
      polygon = Utils.get_polygon_from_lat_lng(lat, lng, polygon_radius)
      polygon = Region.get_polygon_from_raw_polygon_json(polygon.to_json) if polygon_format.present? && polygon_format == 'wkt'

      render json: { raw_polygon_json: polygon }
    end
  end
end 
