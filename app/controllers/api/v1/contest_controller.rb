module Api::V1
  class ContestController < ApiController

    #### Returns data of given contests' regions which are within given distance(kms)
    #### from given coordinates
    def data
      contest_name = params[:contest_name]
      lat          = params[:lat]
      lng          = params[:lng]
      distance_km  = params[:distance_km]&.to_i || 50

      recent_sightings = !params[:recent_sightings].nil? && params[:recent_sightings] == 'true' ?
                          true : false

      include_top_species = !params[:top_species].nil? && params[:top_species] == 'true' ?
                          true : false

      include_top_people = !params[:top_observers].nil? && params[:top_observers] == 'true' ?
                          true : false

      nstart = params[:nstart]&.to_i || 0
      nend   = params[:nend]&.to_i   || 24
      offset = nstart
      limit  = nend - nstart

      fail_message = nil

      fail_message = "No 'contest_name' given" if contest_name.blank?
      raise ApiFail.new(fail_message) unless fail_message.nil?

      fail_message = "No 'lat' given" if lat.blank?
      raise ApiFail.new(fail_message) unless fail_message.nil?

      fail_message = "No 'lng' given" if lng.blank?
      raise ApiFail.new(fail_message) unless fail_message.nil?
      obj = Contest.where title: contest_name

      fail_message = 'No contest found for given name'  if obj.blank?
      raise ApiFail.new(fail_message) unless fail_message.nil?

      obj = obj.first

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