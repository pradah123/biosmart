class SpeciesByRegionsMatview < ActiveRecord::Base
  self.table_name = 'species_by_regions_matview'
  self.primary_key = 'sysid'
  scope :has_scientific_name, -> { where "lower(scientific_name) NOT IN (#{@@filtered_names}) AND scientific_name is not null" }
  scope :has_common_name, -> { where "lower(common_name) NOT IN (#{@@filtered_names})" }

  scope :filter_by_scientific_or_common_name, -> (search_text) {
    where("lower(scientific_name) = ? or lower(common_name) = ?", "#{search_text.downcase}", "#{search_text.downcase}") if search_text.present?
  }
  scope :filter_by_region, -> (region_id) {
    where(region_id: region_id)  if region_id.present?
  }
  @@filtered_names = "'arachnids', 'birds', 'other arthropods',
                     'other invertebrates', 'crustaceans', 'mammals',
                     'amphibians', 'reptiles', 'insects - butterflies and moths',
                     'fungi and friends', 'plants that do not flower', 'plants that flower',
                     'fish', 'insects - beetles', 'insects - ants, bees and wasps',
                     'insects - flies', 'insects - flies'"

  # agelaius phoeniceus
  def readonly?
    true
  end

  def self.get_taxonomy_ids(region_id: nil, search_text: nil)
    taxonomy_ids = []
    taxonomy_ids = SpeciesByRegionsMatview.filter_by_region(region_id)
                                          .has_scientific_name
                                          .has_common_name
                                          .filter_by_scientific_or_common_name(search_text)
                                          .distinct
                                          .pluck(:taxonomy_id)
                                          .compact
    return taxonomy_ids
  end

  def self.get_species_count(region_id:, search_text: nil)
    taxonomy_ids = []
    taxonomy_ids = SpeciesByRegionsMatview.get_taxonomy_ids(search_text: search_text)
    species_count = SpeciesByRegionsMatview.where(region_id: region_id)
                                           .has_scientific_name
                                           .has_common_name
                                           .where(taxonomy_id: taxonomy_ids)
                                           .count(:id)
    return species_count.as_json
  end

  def self.get_regions_by_species(search_text:)
    taxonomy_ids = []
    taxonomy_ids = SpeciesByRegionsMatview.get_taxonomy_ids(search_text: search_text)
    region_ids = []
    region_ids = SpeciesByRegionsMatview.has_scientific_name
                                        .has_common_name
                                        .where(taxonomy_id: taxonomy_ids)
                                        .distinct
                                        .pluck(:region_id)
                                        .compact
    base_region_ids = []
    base_region_ids = Region.where(id: region_ids)
                            .where(base_region_id: nil)
                            .pluck(:id)
    base_region_ids += Region.where(id: region_ids)
                             .where.not(base_region_id: nil)
                             .pluck(:base_region_id)
    regions = Region.where(id: base_region_ids).where(base_region_id: nil)
  end


  def self.get_total_sightings_for_region(region_id:, search_text:)
    locality_species_count = greater_region_species_count = 0
    species_count                = SpeciesByRegionsMatview.get_species_count(region_id: region_id, search_text: search_text)
    locality                     = Region.find_by_id(region_id).get_neighboring_region(region_type: 'locality')
    locality_species_count       = SpeciesByRegionsMatview.get_species_count(region_id: locality.id, search_text: search_text) if locality.present?
    greater_region               = Region.find_by_id(region_id).get_neighboring_region(region_type: 'greater_region')
    greater_region_species_count = SpeciesByRegionsMatview.get_species_count(region_id: greater_region.id, search_text: search_text) if greater_region.present?

    species_count = species_count + locality_species_count + greater_region_species_count
    return species_count
  end

  def self.refresh
    ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW CONCURRENTLY species_by_regions_matview')
  end
end
