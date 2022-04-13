class ObservationsFetchJob < ApplicationJob
  queue_as :default

  def perform 
    Delayed::Worker.logger.info "\n\n\n\n>>>>>>>>>> fetching observations"
    
    Contest.in_progress.each do |contest|
      contest.participations.in_competition do |participant|
        participant.data_sources.each do |data_source|
          # Skip download if no subregion exists
          # Peter: we don't need this if statement- its an extra dbquery we don't need
          # you have the same where statement inside the function which will return an empty array
          # if there are no subregions. So we can just remove the if statement here.
          if Subregion.exists?(region_id: participant.region_id, data_source_id: data_source.id)
            # Peter: the times here should not be the complete time range of the contest- it should 
            # be "time of last fetch" and "time of next fetch", otherwise we will waste a lot of time 
            # processing data which has not changed.
            data_source.fetch_observations participant.region, contest.starts_at, contest.ends_at
          end
        end
      end
    end      

    Delayed::Worker.logger.info ">>>>>>>>>> completed\n\n\n\n"
  end
end
