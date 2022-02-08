require 'sidekiq'
require 'biosmart_queue.rb'

module BioSmart
    Sidekiq.configure_client do |config|
        config.redis = {url: ENV['REDIS_URL'], namespace: :sidekiq}
    end
    
    def self.enqueue_sightings_update()
        
        RegionContest.where(
            contest_id: Contest.select(
                :id
            ).where(
                'CURRENT_TIMESTAMP BETWEEN begin_at AND end_at AND deleted_at IS NULL'
            ), 
            deleted_at: nil
        ).includes(:contest, :region).each do |rc|
            DownloadableRegion.where(
                region_id: rc.region_id,
                deleted_at: nil
            ).find_each do |dr|
                dr.params["d1"] = rc.contest.begin_at.strftime('%Y-%m-%d')
                dr.params["d2"] = rc.contest.end_at.strftime('%Y-%m-%d')
                begin
                    Sidekiq::Client.push(
                        'class' => 'ImportObservationsWorker',
                        'args' => [
                            dr.app_id,
                            RGeo::GeoJSON.encode(rc.region.multi_polygon),
                            dr.params
                        ],
                        'retry' => false
                    )
                rescue StandardError => e
                    Rails.logger.fatal "Error sending message to queue: #{e.message}"
                end
            end
        end
    end

    def self.enqueue_photo_sightings(for_region_id:)
        dr = DownloadableRegion.where(region_id: for_region_id, app_id: 'inaturalist').first
        if dr.blank?
            puts "No Downloadable Region found for region ID: #{for_region_id}"
            return
        end
        photo_params = dr.params
        # include photos
        photo_params["photos"] = true
        # ignore date range
        photo_params.delete("d1")
        photo_params.delete("d2")
        photo_params["per_page"] = 30
        begin
            BiosmartQueue.new.enqueue({
                "app_id" => dr.app_id,
                params: dr.params
            }.to_json)
        rescue StandardError => e
            puts "Error sending message to queue: #{e.message}"
        end
    end
    
end
