class DataSource < ApplicationRecord
  has_and_belongs_to_many :participations
  has_many :observations
  has_many :api_request_logs

  def fetch_observations region, begin_at, end_at
    subregions = Subregion.where(region_id: region_id, data_source_id: id)
    subregions.each do |sr|
      case name
      when 'inaturalist'
        fetch_observations_inat sr, begin_at, end_at, 0
      when 'ebird'
        fetch_observations_ebird sr
      when 'qgame'
        fetch_observations_qgame sr
      when 'observation.org'
        fetch_observations_dot_org sr
      else
        self.send "fetch_#{name}", region
      end
    end
  end

  def fetch_observations_dot_org subregion
    # fetch logic here
    
    []
  end 

  def fetch_inat subregion, begin_at, end_at
    # fetch logic here
    params = subregion.get_params_dict()
    params[:d1] = begin_at.strftime('%F')
    params[:d2] = end_at.strftime('%F')
    page = 0
    loop do
      observations = Inaturalist.get_observations(params)
      ObservationsCreateJob.perform_later self, observations
      break if observations.count <= 0
      params[:page] = page+1
    end 
  end 

  def fetch_ebird subregion
    # fetch logic here
    
    []
  end

  def fetch_qgame subregion
    # fetch logic here
    
    []
  end 
  
end
