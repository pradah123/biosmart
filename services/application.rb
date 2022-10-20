# frozen_string_literal: true

require 'dry/matcher/result_matcher'
require 'dry/monads'
require 'dry/monads/do'

module Service
  module Application
    module ClassMethods
      def call(params, &block)
        service_outcome = new.execute(params)
        if block_given?
          Dry::Matcher::ResultMatcher.call(service_outcome, &block)
        else
          service_outcome
        end
      end
    end

    module InstanceMethods
      include Dry::Monads[:result, :do]

      def execute(params)
        yield validate_params(params)
        super(params)
      end

      def validate_params(params)
        if self.class.constants.include? :ValidationSchema
          validation_outcome = self.class.const_get(:ValidationSchema).call(params)
          return Failure(format(validation_outcome)) if validation_outcome.failure?
        end
        Success(params)
      end

      private

      def format(schema_error)
        schema_error.errors(full: true)
                    .to_h
                    .values
                    .flatten
                    .join('\n')
      end
    end

    def self.included(klass)
      klass.prepend InstanceMethods
      klass.extend ClassMethods
    end
  end
end
