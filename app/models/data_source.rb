class DataSource < ApplicationRecord
  has_and_belongs_to_many :participations
  has_many :observations
  has_many :api_request_logs

  def fetch_observations region, begin_at, end_at
    subregions = Subregion.where(region_id: region_id, data_source_id: id)
    subregions.each do |sr|
      case name
      when 'inaturalist'
        fetch_observations_inat sr, begin_at, end_at
      when 'ebird'
        fetch_observations_ebird sr
      when 'qgame'
        fetch_observations_qgame sr
      when 'observation.org'
        fetch_observations_dot_org sr, begin_at, end_at
      else
        self.send "fetch_#{name}", region
      end
    end
  end

  def fetch_observations_dot_org subregion, begin_at, end_at
    # fetch logic here
    params = subregion.get_params_dict()
    params[:date_after] = begin_at.strftime('%F')
    params[:date_before] = end_at.strftime('%F')
    loop do
      ob_org = Source::ObservationOrg.new(id, **params)
      observations = ob_org.get_observations()
      ObservationsCreateJob.perform_later self, observations
      break if ob_org.done()
      params[:offset] = ob_org.next_offset()
    end 
  end 

  def fetch_inat subregion, begin_at, end_at
    # fetch logic here
    params = subregion.get_params_dict()
    params[:d1] = begin_at.strftime('%F')
    params[:d2] = end_at.strftime('%F')
    page = 1
    loop do
      inat = Source::Inaturalist.new(id, **params)
      observations = inat.get_observations()
      ObservationsCreateJob.perform_later self, observations
      break if page < inat.total_pages()
      params[:page] = page+1
    end
  end 

  def fetch_ebird subregion
    # fetch logic here
    data_source_id = subregion.data_source_id
    params = subregion.get_params_dict()
    params[:back] = (Time.now - begin_at).to_i / (24 * 60 * 60)
    loop do
      ebird = Source::Ebird.new(id, **params)
      observations = qgame.get_observations()
      ObservationsCreateJob.perform_later self, observations
      break if qgame.done()
      params[:offset] = qgame.next_offset()
    end
  end

  def fetch_qgame subregion
    # fetch logic here
    params = subregion.get_params_dict()
    params[:start_dttm] = begin_at.strftime('%F')
    params[:end_dttm] = end_at.strftime('%F')
    loop do
      qgame = Source::QGame.new(id, **params)
      observations = qgame.get_observations()
      ObservationsCreateJob.perform_later self, observations
      break if qgame.done()
      params[:offset] = qgame.next_offset()
    end
  end 
  
end
