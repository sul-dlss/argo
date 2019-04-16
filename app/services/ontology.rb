# frozen_string_literal: true

class Ontology
  class << self
    def key?(key)
      @data.key?(key)
    end

    # Yields each term to the block provided
    def options
      @data.map do |k, _v|
        yield property(k)
      end
    end

    def property(key)
      Term.new(@data[key].merge(key: key))
    end
  end

  class Term
    def initialize(uri:, human_readable:, key:, deprecation_warning: nil)
      @label = human_readable
      @uri = uri
      @deprecation_warning = deprecation_warning
      @key = key
    end

    attr_reader :label, :uri, :deprecation_warning, :key
  end
end
