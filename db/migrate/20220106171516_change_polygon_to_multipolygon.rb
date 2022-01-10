class ChangePolygonToMultipolygon < ActiveRecord::Migration[6.1]
    def up
        add_column :regions, :multi_polygon, :multi_polygon, srid: 4326, geographic: true
        add_index  :regions, :multi_polygon, using: :gist
        Region.all.each do |r|
            factory = RGeo::Geographic.spherical_factory(srid: 4326)
            r.multi_polygon = factory.multi_polygon([r.polygon])
            r.save
        end
        remove_column :regions, :polygon
    end
    def down
        remove_column :regions, :multi_polygon
        add_column :regions, :polygon, :st_polygon, srid: 4326, geographic: true
        add_index  :regions, :polygon, using: :gist
    end
end
