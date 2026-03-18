# frozen_string_literal: true

class DescriptionImport
  include Dry::Monads[:result]

  class_attribute :permitted_types, default: Cocina::Models::Validators::DescriptionTypesValidator.new(nil, nil)
                                             .send(:types_yaml).values.flatten.pluck('value')

  def self.import(csv_row:)
    new(csv_row:).import
  end

  def initialize(csv_row:)
    @csv_row = csv_row
  end

  def import
    params = {}

    # The source_id and druid are only there for the user to reference and should be ignored for data processing
    # druid is only on the bulk sheet
    headers = @csv_row.headers.excluding('source_id', 'druid')
    headers.sort_by! { |address| sortable_address(address) }

    headers.each do |address|
      visit(params, split_address(address), @csv_row[address]) if @csv_row[address]
    end

    Success(DescriptionImportFilter.filter(compact_params(params)))
  rescue Cocina::Models::ValidationError => e
    Failure([e.message])
  end

  private

  def split_address(address)
    address.scan(/[[:alpha:]]+|[[:digit:]]+/)
           .map { |item| /\d+/.match?(item) ? item.to_i - 1 : item.to_sym }
  end

  def sortable_address(address)
    split_address(address).map do |part|
      next part unless part.is_a?(Integer)

      part.to_s.rjust(4, '0')
    end.join('.')
  end

  def nest_hashes(value, *keys)
    return value if keys.empty?

    key = keys.shift
    value = normalize_type(value) if key == :type
    val = keys.empty? ? value : nest_hashes(value, *keys)
    key.is_a?(Integer) ? [].tap { |arr| arr[key] = val } : { key => val }
  end

  # If the type is found in the permitted types, return it as-is; otherwise, return it in downcase.
  # Almost all types are expected to be downcase, but some are not (e.g. OCLC, ISSN, etc.)
  def normalize_type(value)
    permitted_types.include?(value) ? value : value.downcase
  end

  # @params [Array,Hash] what a tree or list like data structure. It's one of the nodes in the Cocina descriptive
  # @params [Array<Symbol,Integer>] rest the "path" we have to follow to get to the location in the tree/list.
  # @params [String] value the data to write
  # @params [Array] path address of the path we took to get to this node
  def visit(what, rest, value, path = [])
    key, *rst = rest
    visit_regular(what, key, rst, value, path)
  end

  def visit_regular(what, key, rest, value, path)
    # Check for key, because `nil` can still be legitimate value in hash
    unless key?(what, key)
      what[key] = nest_hashes(value, *rest)
      return
    end

    return what[key] = value if rest.empty?

    visit(what[key], rest, value, [*path, key])
  end

  def key?(what, key)
    case what
    when Array
      (0...what.size).cover?(key)
    when Hash
      what.key?(key)
    end
  end

  def compact_params(params)
    params.each do |key, value|
      next unless value.is_a?(Array)

      params[key].compact!
      params[key].map { |param| compact_params(param) }
    end
  end
end
