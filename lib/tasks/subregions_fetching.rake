namespace :subregions_fetching do
  desc 'create subregions fetching jobs'
  task schedule: :environment do
    Subregion.get_subregions_to_fetch(Time.now).each do |s|
      s.data_source.fetch_and_store_observations.perform_later
    end  
  end
end

