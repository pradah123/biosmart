module BioSmart

    def self.enqueue_sightings_update(for_region_id:)
        region = ENV["SQS_REGION"] || "ap-southeast-2"
        queue_url = ENV["SQS_URL"] || "https://sqs.ap-southeast-2.amazonaws.com/461130176523/biosmart-import-queue-test"
        sqs_client = Aws::SQS::Client.new(region: region)

        DownloadableRegion.where(
            region_id: for_region_id, 
            deleted_at: nil
        ).find_each do |dr|
            event_json = {
                "app-id" => dr.app_id,
                params: dr.params
            }.to_json
            begin
                sqs_client.send_message(
                    queue_url: queue_url,
                    message_body: event_json
                )
            rescue StandardError => e
                puts "Error sending message: #{e.message}"
            end
        end
    end    
    
end
