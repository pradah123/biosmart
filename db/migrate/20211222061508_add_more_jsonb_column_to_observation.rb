class AddMoreJsonbColumnToObservation < ActiveRecord::Migration[6.1]
    def up
        add_column :observations, :more, :jsonb, default: '{}'
        more_array = ActiveRecord::Base.connection.execute('
            SELECT 
                id, 
                replace(json::json->>\'locId\', \'"\', \'\') as "locId", 
                replace(split_part(json::json->>\'obsDt\', \' \', 1), \'"\', \'\') as "obsDt", 
                replace(split_part(json::json->>\'obsDt\', \' \', 2), \'"\', \'\') as "obsTime", 
                replace(json::json->>\'subId\', \'"\', \'\') as "subId",
                ST_Y(location::geometry) as lat,
                ST_X(location::geometry) as lng
            FROM 
                observations 
            WHERE 
                app_id = \'ebird\';
        ')
        more_array.each do |more_hash|
            id = more_hash["id"]
            hash = more_hash.except("id")
            Observation.find(id).update(more: hash)
        end
        add_index :observations, "(more->'locId')"
        add_index :observations, "(more->'obsDt')"
        add_index :observations, "(more->'obsTime')"
        add_index :observations, "(more->'subId')"
        add_index :observations, "(more->'lat')"
        add_index :observations, "(more->'lng')"
    end
    def down
        remove_column :observations, :more
    end
end
