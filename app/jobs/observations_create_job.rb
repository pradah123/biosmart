class ObservationsCreateJob < ApplicationJob
  queue_as :default

  def perform data_source, observations
    Delayed::Worker.logger.info "\n\n\n\n>>>>>>>>>> processing #{observations.count} observations from #{data_source.name}"
    
    nupdates = 0
    nupdates_no_change = 0
    nupdates_failed = 0
    nfields_updated = 0
    ncreates = 0
    ncreates_failed = 0

    observations.each do |params|
      obs = Observation.find_by_unique_id params[:unique_id]
      params[:data_source_id] = data_source.id

      if obs.nil?

        obs = Observation.new params
        if obs.save
          ncreates += 1
        else
          ncreates_failed += 1          
          Delayed::Worker.logger.info "\n\n\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
          Delayed::Worker.logger.info "Create failed on observation"
          Delayed::Worker.logger.info obs.inspect
          Delayed::Worker.logger.info params.inspect
          Delayed::Worker.logger.info "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n\n"
        end

      else

        obs.attributes = params
        if obs.changed.empty?
          nupdates_no_change += 1  
        else
          nupdates += 1  
          nfields_updated += obs.changed.length
          if obs.save

          else  
            nupdates_failed +=1 
            Delayed::Worker.logger.info "\n\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
            Delayed::Worker.logger.info "Update failed on observation #{obs.id}"
            Delayed::Worker.logger.info obs.inspect
            Delayed::Worker.logger.info params.inspect
            Delayed::Worker.logger.info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n\n"
          end
        end

      end
    end

    ApiRequestLog.create! job_id: self.job_id, nobservations: observations.length, data_source_id: data_source, ncreates: ncreates, ncreates_failed: ncreates_failed, nupdates: nupdates, nupdates_no_change: nupdates_no_change, nupdates_failed: nupdates_failed  
    
    Delayed::Worker.logger.info ">>>>>>>>>> completed\n\n\n\n"
  end
end
