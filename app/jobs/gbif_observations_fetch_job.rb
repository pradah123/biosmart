class GbifObservationsFetchJob < ApplicationJob
  queue_as :queue_gbif_observations_fetch

  def perform (start_dt: nil, end_dt: nil, region_id: nil)
    Delayed::Worker.logger.info "\n\n\n\n>>>>>>>>>> fetching observations"
    greater_regions = []
    if !region_id.nil?
      greater_regions = Region.where(id: region_id)
    else
      Region.all.each { |r|
        largest_nr = r.get_largest_neighboring_region()
        greater_regions.push(largest_nr) if !largest_nr.nil?
      }
    end
    greater_regions.each do |region|
      data_source = DataSource.where("name = 'gbif'").first
      starts_at = ends_at = nil

      if start_dt.nil? || end_dt.nil? ## Evaluate start and end dates only if are not given
        ends_at = Time.now()
        latest_observation = region.observations.order("observed_at").last

        ## If there are observations exist for the region then fetch data from latest observed at date till now
        ## else fetch 3 years back data(as it can be a new region)
        if !latest_observation.blank? && !latest_observation.observed_at.blank?
          starts_at = latest_observation.observed_at
        else
          starts_at = ends_at - Utils.convert_to_seconds(unit:'year', value: 3)
        end
      else
        starts_at = start_dt.to_time
        ends_at = end_dt.to_time
      end
      data_source.fetch_observations region, starts_at, ends_at
    end

    Delayed::Worker.logger.info ">>>>>>>>>> completed\n\n\n\n"
  end

end
