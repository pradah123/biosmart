module Api::V1
  class ContestController < ApiController

    ### Find out whether given coordinates and region are within 50kms reach or not
    def is_region_near lat, lng, region, polygon_geojson
      geokit_point = Geokit::LatLng.new lat, lng

      is_near_region = false
      region.get_geokit_polygons.each do |polygon|
        if polygon.contains?(geokit_point)
          is_near_region = true
          break
        end
      end
      if is_near_region == false
        polygon_geojson.each do |polygon|
          polygon['coordinates'].each { |c|
            p1 = Geokit::LatLng.new c[1] , c[0]
            p2 = Geokit::LatLng.new lat, lng
            dist = p1.distance_to(p2, units: :kms).ceil()
            if dist < 50
              is_near_region = true
              logger.debug "is_near_region : true , Distance : #{p1.distance_to(p2, units: :kms).ceil}"
              break
            end
          }
        end
      end
      return is_near_region

    end

    #### Returns data of given contests' regions which are near to 50km from given coordinates
    def data
      contest_name = params[:contest_name]
      lat = params[:lat]
      lng = params[:lng]

      recent_sightings = params[:recent_sightings] || 'false'
      nstart = params[:nstart]&.to_i || 0
      nend = params[:nend]&.to_i || 24
      offset = nstart
      limit = nend - nstart

      fail_message = nil
      fail_message = { status: 'fail', message: 'no contest_name is given' } if contest_name.nil?
      unless fail_message.nil?
        render json: fail_message
        return
      end

      obj = Contest.where title: contest_name
      if obj.nil? || obj.blank?
        fail_message = { status: 'fail', message: 'no contest found for given name' }
        render json: fail_message
        return
      end
      obj = obj.first

      participations = []
      if obj.regions.count > 0
        obj.participations.ordered_by_observations_count.each.with_index(1) do |participant,i|
          region = participant.region
          polygon_geojson = region.raw_polygon_json
          if polygon_geojson.nil?
            break
          end
          polygon_geojson = JSON.parse polygon_geojson
          polygon_geojson = [polygon_geojson] unless polygon_geojson.kind_of?(Array)

          is_near_region = is_region_near(lat, lng, region, polygon_geojson)

          if is_near_region == true
            region = {
              ### Region specific data
              region_name: region.name,
              description: region.description,
              logo_image_url: region.logo_image_url,
              header_image: region.header_image,
              polygon: polygon_geojson,
              lat: participant.region.lat,
              lng: participant.region.lng,

              ## Participation data i.e. Region's data related to given contest
              observations_count: participant.observations_count,
              identifications_count: participant.identifications_count,
              species_count: participant.species_count,
              people_count: participant.people_count,
              bioscore: participant.bioscore,
              physical_health_score: participant.physical_health_score,
              mental_health_score: participant.mental_health_score,
              top_species: participant.get_top_species(10).map { | species |
                {
                  name:  species[0],
                  count: species[1]
                }},
              top_observers: participant.get_top_people(10).map { | observers |
                {
                  name:  observers[0],
                  observations_count: observers[1]
                }}
            }
            if recent_sightings == 'true'
              region['recent_sightings'] =  participant.observations.has_scientific_name.recent.offset(offset).limit(limit).map { |obs| {
                scientific_name: obs.scientific_name,
                common_name: obs.common_name,
                creator_name: (obs.creator_name.nil? ? '' : obs.creator_name),
                observed_at: "#{ obs.observed_at.strftime '%Y-%m-%d %H:%M' } UTC",
                image_urls: obs.observation_images.pluck(:url),
                lat: obs.lat,
                lng: obs.lng
              }}
            end
            participations.push(region)
          end
        end
      end
      ret = { 'regions': participations }
      render_success ret
    end
  end
end 