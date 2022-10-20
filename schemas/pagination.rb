require 'dry/validation'

module AppSchema
  module Pagination
    def self.extended(object)
      super(object)
      object.instance_eval do
        optional(:offset).filled(:integer, gteq?: 0)
        optional(:limit).filled(:integer, gt?: 0)
      end
    end
  end
end
