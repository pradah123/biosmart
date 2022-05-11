module CountableStatistics
  extend ActiveSupport::Concern
  included do

    def add_and_compute_statistics obs
      self.observations << obs      
      reset_statistics
    end  
   
    def get_nspecies
      self.observations.has_accepted_name.ignore_species_code.select(:accepted_name).distinct.count
    end  
    
    def get_nidentifications
      self.observations.pluck(:identifications_count).sum
    end

    def reset_statistics
      update_column :observations_count, self.observations.count
      update_column :species_count, self.observations.pluck(:accepted_name).uniq.count
      update_column :identifications_count, self.observations.pluck(:identifications_count).sum
      update_column :people_count, self.observations.pluck(:creator_name).compact.uniq.count
    end  

  end
end
