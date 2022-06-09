class ObservationsFetchJob < ApplicationJob
  queue_as :queue_observations_fetch

  def perform 
    Delayed::Worker.logger.info "\n\n\n\n>>>>>>>>>> fetching observations"
    
    Contest.in_progress.each do |contest|
      contest.participations.in_competition.each do |participant|
        if participant.is_active?
          participant.data_sources.each do |data_source|
            data_source.fetch_observations participant.region, contest.starts_at, contest.ends_at
          end
        end
      end
    end

    Delayed::Worker.logger.info ">>>>>>>>>> completed\n\n\n\n"
  end
  
end
