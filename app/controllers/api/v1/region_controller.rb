require './services/region'

module Api::V1
  class RegionController < ApiController

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
          render json: region_hash
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def undiscovered_species
      search_params = params.to_unsafe_h.symbolize_keys
      top_n = search_params[:n]&.to_i || 10
      Service::Region::Show.call(search_params) do |result|
        result.success do |region|
          undiscovered_species = region.get_undiscovered_species(top_n: top_n)
          render json: { undiscovered_species: undiscovered_species }
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
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

  end
end 
