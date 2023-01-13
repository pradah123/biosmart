class ObservationsFetchJob < ApplicationJob
  queue_as :queue_observations_fetch

  def perform
    Delayed::Worker.logger.info "\n\n\n\n"
    Delayed::Worker.logger.info ">>>>>>>>>> ObservationsFetchJob fetching observations"
    
    regions = []
    regions = Region.get_regions_for_data_fetching()

    r_hash = []
    r_hash = Region.get_data_sources_and_date_range_for_data_fetch(regions: regions)

    r_hash.each do |r|
      r[:data_sources].each do |data_source|
        next unless data_source.present?
        Delayed::Worker.logger.info ">>>>>>>>>>>>>>>>>>>>> ObservationsFetchJob fetching data for region: #{r[:region].name}, data_source: #{data_source[:data_source].name}, starts_at: #{data_source[:starts_at]}"
        data_source[:data_source].fetch_observations r[:region], data_source[:starts_at], data_source[:ends_at]
      end
    end

    Delayed::Worker.logger.info ">>>>>>>>>> ObservationsFetchJob completed\n\n\n\n"
  end

end
