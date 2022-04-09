module Api::V1
  class RegionController < ApiController

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

  end
end 

