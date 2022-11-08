namespace :update_gbif_observations_matview do
  desc 'Update the GBIF Observations materialized view'
  task refresh: :environment do
    GbifObservationsMatview.refresh
  end
end
