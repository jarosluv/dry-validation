require 'dry-equalizer'
require 'dry-configurable'
require 'dry-container'

require 'dry/validation/schema'
require 'dry/validation/schema/form'
require 'dry/validation/schema/json'

module Dry
  module Validation
    MissingMessageError = Class.new(StandardError)
    InvalidSchemaError = Class.new(StandardError)

    def self.messages_paths
      Messages::Abstract.config.paths
    end

    def self.Schema(base = Schema, **options, &block)
      schema_class = Class.new(base.is_a?(Schema) ? base.class : base)

      dsl_opts = {
        schema_class: schema_class,
        registry: schema_class.registry,
        parent: options[:parent]
      }

      dsl = Schema::Value.new(dsl_opts)
      dsl.instance_exec(&block)

      klass = dsl.schema_class

      klass.configure do |config|
        config.rules = config.rules + (options.fetch(:rules, []) + dsl.rules)
        config.checks = config.checks + dsl.checks
        config.path = dsl.path

        if dsl.type_map.size > 0
          config.type_map = type_map(dsl.type_map, config.input_processor)
        end
      end

      if options[:build] == false
        klass
      else
        klass.new
      end
    end

    def self.Form(options = {}, &block)
      Validation.Schema(Schema::Form, options, &block)
    end

    def self.JSON(options = {}, &block)
      Validation.Schema(Schema::JSON, options, &block)
    end

    def self.type_map(type_map, input_processor)
      type_map.each_with_object({}) do |(name, spec), result|
        result[name] = Array(spec)
          .map { |id| Types["#{input_processor}.#{id}"] }
          .reduce(:|)
      end
    end
  end
end
