# frozen_string_literal: true

class DescriptionImport
  include Dry::Monads[:result]

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
    headers = @csv_row.headers.excluding("source_id", "druid")
    headers.sort_by! { |address| sortable_address(address) }

    headers.each do |address|
      visit(params, split_address(address), @csv_row[address]) if @csv_row[address]
    end

    Success(Cocina::Models::Description.new(compact_params(params)))
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

      part.to_s.rjust(3, "0")
    end.join(".")
  end

  def nest_hashes(value, *keys)
    return value if keys.empty?

    key = keys.shift
    val = keys.empty? ? value : nest_hashes(value, *keys)
    key.is_a?(Integer) ? [].tap { |arr| arr[key] = val } : {key => val}
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
