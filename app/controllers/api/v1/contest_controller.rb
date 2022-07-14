module Api::V1
  class ContestController < ApiController

    #### Returns data of given contests' regions which are within given distance(kms)
    #### from given coordinates
    def data
      contest_name = params[:contest_name]
      lat          = params[:lat]
      lng          = params[:lng]
      distance_km  = params[:distance_km] || 50

      recent_sightings = !params[:recent_sightings].nil? && params[:recent_sightings] == 'true' ?
                          recent_sightings = true : recent_sightings = false

      nstart = params[:nstart]&.to_i || 0
      nend   = params[:nend]&.to_i   || 24
      offset = nstart
      limit  = nend - nstart

      fail_message = nil
      fail_message = { status: 'fail', message: 'no contest_name is given' } if contest_name.nil?

      unless fail_message.nil?
        render json: fail_message
        return
      end

      obj = Contest.where title: contest_name

      if obj.blank?
        fail_message = { status: 'fail', message: 'no contest found for given name' }
        render json: fail_message
        return
      end
      obj = obj.first

      participations = []
      if obj.regions.count > 0
        obj.participations.ordered_by_observations_count.each do |participant|
          region = participant.region
          polygon_geojson = region.get_polygon_json
          if polygon_geojson.nil?
            break
          end

          is_region_near_to_point = false
          if (!lat.nil? && !lng.nil?)
            is_region_near_to_point = region.is_region_near_to_point(lat, lng, distance_km)
          else
            is_region_near_to_point = true ## If lat or lng not given then get all regions data related to the contest
          end
          if is_region_near_to_point == true
            data = participant.format_data true, true, recent_sightings, offset, limit
            participations.push(data)
          end
        end
      end

      render_success participations
    end
  end
end 