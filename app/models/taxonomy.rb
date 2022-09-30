class Taxonomy < ApplicationRecord
    has_many :observations

    validates :taxon_id, presence: true
    validates :taxon_rank, exclusion: { in: %w[unranked] }

    def build_record(params:)
        obj = self
        obj.taxon_id = params['taxonID'] || ''
        obj.scientific_name = params['scientificName'] || ''
        obj.canonical_name = params['canonicalName'] || ''
        obj.accepted_name = params['accepted'] || params['canonicalName'] || params['scientificName'] || ''
        obj.accepted_name_usage_id = params['acceptedNameUsageID'] || ''
        obj.kingdom = params['kingdom'] || ''
        obj.phylum = params['phylum'] || ''
        obj.class_name = params['class'] || ''
        obj.taxonomic_status = params['taxonomicStatus'] || ''
        obj.taxon_rank = params['taxonRank'] || ''
        obj.generic_name = params['genericName'] || ''
        obj.source = params['source'] || 'manual'
        return obj
    end

    # Store taxonomy record using given params
    def self.store_taxonomy(params:)
      taxon_id = params['taxonID']
      taxon_id = taxon_id.match(/(\d+)/).captures[0] 
      taxonomy = Taxonomy.find_by_taxon_id(taxon_id)
      taxonomy = Taxonomy.new() unless taxonomy.present?
      record   = taxonomy.build_record(params: params)

      if record.valid? && (record.new_record? || record.changed?)
        begin 
          record.save
        rescue => e
          Rails.logger.info ">>> Taxonomy::store_taxonomy - Error occured while saving taxonomy record #{e.full_message}"
          return nil
        end
        Rails.logger.info ">>> Taxonomy::store_taxonomy - Successfully stored record for taxon_id #{record.taxon_id}"

        return record
      else
        return nil
      end

    end

    # Some taxonomies have synonym taxonomy and have accepted_name_usage_id which matches with taxon_id
    # of that synonym.
    # We need to update those taxonomies' accepted_name with synonym taxonomy's accepted_name
    def update_accepted_name
        case taxonomic_status.downcase
        when 'accepted'
            taxon_updated = Taxonomy.where(accepted_name_usage_id: taxon_id).where.not(accepted_name: accepted_name).update_all(accepted_name: accepted_name) if accepted_name.present?
            Rails.logger.info ">>>>> Taxonomy::update_scientific_name/#{taxonomic_status} :: Updated accepted_name #{accepted_name} for taxonomies having accepted_name_usage_id as #{taxon_id},taxon_updated:#{taxon_updated}"
        else
            taxonomy = Taxonomy.find_by_taxon_id(accepted_name_usage_id)
            parent_accepted_name = taxonomy&.accepted_name
            taxon_updated = self.update(accepted_name: parent_accepted_name) if parent_accepted_name.present? && parent_accepted_name != accepted_name
            Rails.logger.info ">>>>> Taxonomy::update_scientific_name/#{taxonomic_status} :: Updated accepted_name #{accepted_name} for taxon_id-#{taxon_id}, taxon_updated:#{taxon_updated}"
        end   
    end
                  
    

    rails_admin do
        list do
            field :id
            field :taxon_id
            field :source
            field :scientific_name
            field :canonical_name
            field :accepted_name
            field :generic_name
            field :accepted_name_usage_id
            field :kingdom
            field :phylum
            field :class_name
            field :taxonomic_status
            field :taxon_rank
            field :created_at      
        end
        edit do 
            field :id
            field :taxon_id
            field :source
            field :scientific_name
            field :canonical_name
            field :accepted_name
            field :generic_name
            field :accepted_name_usage_id
            field :kingdom
            field :phylum
            field :class_name
            field :taxonomic_status
            field :taxon_rank
            field :created_at
        end
        show do
            field :id
            field :taxon_id
            field :source
            field :scientific_name
            field :canonical_name
            field :accepted_name
            field :generic_name
            field :accepted_name_usage_id
            field :kingdom
            field :phylum
            field :class_name
            field :taxonomic_status
            field :taxon_rank
            field :created_at      
            field :created_at
        end
    end
end
