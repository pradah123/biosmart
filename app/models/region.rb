class Region < ApplicationRecord
    has_many :contests, through: :region_contest
end
