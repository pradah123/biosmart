class Subregion < ApplicationRecord
  belongs_to :region
  belongs_to :data_source

  def get_params_dict()
    return JSON.parse(params_json, symbolize_names: true)
  end
end
