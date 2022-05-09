module CountableStatistics
  extend ActiveSupport::Concern
  included do

    def get_nobservations
      self.observations.count
    end  
   
    def get_nspecies
      self.observations.has_accepted_name.ignore_species_code.select(:accepted_name).distinct.count
    end  
    
    def get_nidentifications
      self.observations.pluck(:identifications_count).sum
    end

    def get_nparticipants
      self.observations.pluck(:creator_name).compact.uniq.count
    end  

  end
end
