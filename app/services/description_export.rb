# frozen_string_literal: true

# This exports the cocina description to a rectangularized data structure
class DescriptionExport
  def self.export(description)
    new(description).export
  end

  def initialize(description)
    @description = description
  end

  def export
    flatten(squish(description.to_h))
  end

  # Transform the COCINA datastructure into a hash structure (converting arrays to hashes with index for keys)
  def squish(source)
    return source unless source.is_a? Hash

    source.each_with_object({}) do |(k, value), sink|
      new_value = if value.is_a? Array
                    # Transform to hash
                    value.each_with_object({}).with_index { |(el, acc), i| acc[i] = squish(el) }
                  else
                    squish(value)
                  end
      sink[k.to_s] = new_value.presence
    end.compact
  end

  # Change the nested hash structure into a single level hash
  def flatten(source)
    source.each_with_object({}) do |(key, value), sink|
      if value.is_a? String
        sink[key] = value
      else
        flatten(value).each do |k, v|
          new_key = k.start_with?(/\d/) ? "#{key}#{k}" : "#{key}:#{k}"
          sink[new_key] = v
        end
      end
    end
  end

  attr_reader :description
end
