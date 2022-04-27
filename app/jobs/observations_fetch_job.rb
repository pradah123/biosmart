class ObservationsFetchJob < ApplicationJob
  queue_as :default

  def perform 
    Delayed::Worker.logger.info "\n\n\n\n>>>>>>>>>> fetching observations"
    
    Contest.in_progress.each do |contest|
      contest.participations.in_competition.each do |participant|
        participant.data_sources.each do |data_source|

          data_source.fetch_observations participant.region, participant.starts_at, participant.last_submission_accepted_at
        
        end
      end
    end

    Delayed::Worker.logger.info ">>>>>>>>>> completed\n\n\n\n"
  end

end
