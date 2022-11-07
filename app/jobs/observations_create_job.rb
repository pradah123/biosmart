class ObservationsCreateJob < ApplicationJob
  queue_as :queue_observations_create

  def perform data_source, observations, participant_id = nil
    ScoutApm::Transaction.ignore!
    
    Delayed::Worker.logger.info "\n\n\n\n"
    Delayed::Worker.logger.info ">>>>>>>>>>ObservationsCreateJob processing #{observations.count} observations from #{data_source.name}"
    Delayed::Worker.logger.info "ObservationsCreateJob >> participant_id: #{participant_id}"
    nupdates = 0
    nupdates_no_change = 0
    nupdates_failed = 0
    nfields_updated = 0
    ncreates = 0
    ncreates_failed = 0

    observations.each do |params|
      obs = Observation.find_by_unique_id params[:unique_id]
      params[:data_source_id] = data_source.id
      image_urls = (params.delete :image_urls) || []
      
      if obs.nil?
 
        obs = Observation.new params
        
        if obs.save
          ncreates += 1
          obs.update_to_regions_and_contests(data_source_id: data_source.id, participant_id: participant_id)
          image_urls.each do |url|
            ObservationImage.create! observation_id: obs.id, url: url
          end
          TaxonomyUpdateJob.perform_later(scientific_name: obs.scientific_name) unless obs.taxonomy.present?
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
          if obs.update_to_regions_and_contests(data_source_id: data_source.id, participant_id: participant_id)
            nupdates += 1
          else
            nupdates_failed +=1
            Delayed::Worker.logger.info "\n\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
            Delayed::Worker.logger.info "Update to regions and contests failed on observation #{obs.id}"
            Delayed::Worker.logger.info obs.inspect
            Delayed::Worker.logger.info params.inspect
            Delayed::Worker.logger.info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n\n\n"
          end
          TaxonomyUpdateJob.perform_later(scientific_name: obs.scientific_name) unless obs.taxonomy.present?
        else
          nupdates += 1  
          nfields_updated += obs.changed.length
          if obs.save
            obs.update_to_regions_and_contests(data_source_id: data_source.id, participant_id: participant_id)
            TaxonomyUpdateJob.perform_later(scientific_name: obs.scientific_name) unless obs.taxonomy.present?
            current_image_urls = obs.observation_images.pluck :url
            if current_image_urls-image_urls!=[] 
              # if the images given are not the same as the ones present, delete the old
              # ones and remake them
              obs.observation_images.delete_all
              image_urls.each do |url|
                ObservationImage.create! observation_id: obs.id, url: url
              end
            end  

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
