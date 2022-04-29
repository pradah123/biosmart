class ResetTimes < ActiveRecord::Migration[6.1]
  def change
    Region.each do |r|
      r.set_time_zone_from_polygon
    end
  end
end
