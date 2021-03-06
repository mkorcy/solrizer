require 'ostruct'

module Solrizer
  class Suffix

    def initialize(*fields)
      @fields = fields.flatten
    end

    def multivalued?
      has_field? :multivalued
    end

    def stored?
      has_field? :stored
    end

    def indexed?
      has_field? :indexed
    end

    def has_field? f
      f.to_sym == :type or @fields.include? f.to_sym
    end

    def data_type
      @fields.first
    end

    def to_s

      raise Solrizer::InvalidIndexDescriptor, "Missing datatype for #{@fields}" unless data_type

      field_suffix = [config.suffix_delimiter]

      config.fields.select { |f| has_field? f }.each do |f|
        key = :"#{f}_suffix"
        field_suffix << if config.send(key).is_a? Proc
          config.send(key).call(@fields)
        else
          config.send(key)
        end
      end
      
      field_suffix.join
    end

    def self.config
      @config ||= OpenStruct.new :fields => [:type, :stored, :indexed, :multivalued],
        suffix_delimiter: '_',
        type_suffix: (lambda do |fields|
          type = fields.first
          case type
          when :string, :symbol # TODO `:symbol' usage ought to be deprecated
            's'
          when :text
            't'
          when :text_en
            'te'
          when :date, :time
            'dt'
          when :integer
            'i'
          when :boolean
            'b'
          else
            raise Solrizer::InvalidIndexDescriptor, "Invalid datatype `#{type.inspect}'. Must be one of: :date, :time, :text, :text_en, :string, :symbol, :integer, :boolean"
          end
        end),
        stored_suffix: 's',
        indexed_suffix: 'i',
        multivalued_suffix: 'm'
    end

    def config
      @config ||= self.class.config.dup
    end
  end
end
