class FetchForSubregionJob < ApplicationJob
  
  def perform subregion_id
    Delayed::Worker.logger.info ">>>>>>>>>> processing subregion #{subregion_id}"
    
    subregion = Subregion.find_by_id subregion_id

    if subregion.nil?
      Delayed::Worker.logger.info "  subregion #{subregion_id} does not exist"
    elsif subregion.processing?
      Delayed::Worker.logger.info "  subregion #{subregion_id} already processing"
    else
      Delayed::Worker.logger.info "  subregion #{subregion_id} in #{subregion.region.name} processing"
      subregion.fetch_and_store_observations
    end

    Delayed::Worker.logger.info ">>>>>>>>>> completed processing subregion #{subregion_id}"
  end
end
