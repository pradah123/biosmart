module BioSmart
    def self.enqueue_sightings_update(for_region_id:)
        DownloadableRegion.where(region_id: for_region_id).find_each do |dr|
            event_json = {
                "app-id" => dr.app_id,
                params: dr.params
            }.to_json
            puts 'curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d ' + "'#{event_json}'"
        end
    end
end
