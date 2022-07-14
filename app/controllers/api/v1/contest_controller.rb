module Api::V1
  class ContestController < ApiController

    #### Returns data of given contests' regions which are within given distance(kms)
    #### from given coordinates
    def data
      contest_name = params[:contest_name]
      lat          = params[:lat]
      lng          = params[:lng]
      distance_km  = params[:distance_km]&.to_i || 50

      recent_sightings = params[:recent_sightings].present? && params[:recent_sightings] == 'true'
      include_top_species = params[:top_species].present? && params[:top_species] == 'true'
      include_top_people = params[:top_observers].present? && params[:top_observers] == 'true'

      nstart = params[:nstart]&.to_i || 0
      nend   = params[:nend]&.to_i   || 24
      offset = nstart
      limit  = nend - nstart

      raise ApiFail.new("No 'contest_name' given") if contest_name.blank?
      raise ApiFail.new("No 'lat' given") if lat.blank?
      raise ApiFail.new("No 'lng' given") if lng.blank?

      obj = Contest.find_by_title contest_name
      raise ApiFail.new('No contest found for given name') if obj.blank?

      participations = []
      if obj.regions.count > 0
        obj.participations.ordered_by_observations_count.each do |participant|
          region = participant.region
          polygon_geojson = region.get_polygon_json
          if polygon_geojson.nil?
            break
          end

          is_region_near_to_point = region.is_region_near_to_point(lat, lng, distance_km)

          if is_region_near_to_point == true
            data = participant.format_data include_top_species, include_top_people, recent_sightings, offset, limit
            participations.push(data)
          end
        end
      end

      render_success participations
    end
  end
end 
