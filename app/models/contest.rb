class Contest < ApplicationRecord
    has_many :regions, through: :region_contest
end
