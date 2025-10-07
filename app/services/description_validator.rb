# frozen_string_literal: true

# Validate the descriptive metadata spreadsheet
class DescriptionValidator
  def initialize(csv, bulk_job: false)
    @csv = csv
    @headers = csv.headers
    @bulk_job = bulk_job # indicates if validating from a bulk job
    @errors = []
  end

  def valid?
    validate_duplicate_headers
    validate_title_headers
    validate_title_value_for_type
    validate_title_value_for_structured_type
    validate_title_type_for_structured_value
    validate_title_types_and_values
    validate_structured_title_types_and_values
    validate_header_paths
    validate_cell_values
    if @bulk_job
      validate_druid_headers
      validate_druid_rows
    end
    errors.empty?
  end

  def errors
    @errors.uniq
  end

  def validate_cell_values
    @csv.each.with_index(2) do |row, i|
      @headers.excluding('druid').each do |header|
        location = row['druid'] || "row #{i}"
        cell_value = row[header]&.strip
        @errors << "Value error: #{location} has 0 value in #{header}." if cell_value == '0'
        @errors << "Value error: #{location} has spreadsheet formula error in #{header}." if %w[#NA #REF! #VALUE?
                                                                                                #NAME?].include? cell_value
      end
    end
  end

  def validate_duplicate_headers
    duplicate_headers.each do |header|
      @errors << "Duplicate column headers: The header #{header} should occur only once."
    end
  end

  def validate_title_headers
    return if title_value_header? || title_structured_value_header? || title_parallel_value_header?

    @errors << 'Title column not found.'
  end

  # verify that each titleX.type has a corresponding titleX.value or titleX.structuredValue1.value
  def validate_title_value_for_type
    @headers.each do |header|
      next unless (match = header&.match(/\Atitle(\d+)\.type\z/))

      expected_header1 = "title#{match[1]}.value"
      expected_header2 = "title#{match[1]}.structuredValue1.value"

      next if @headers.include?(expected_header1) || @headers.include?(expected_header2)

      @errors << "Missing title value for #{header}. Expected either #{expected_header1} or #{expected_header2}."
    end
  end

  # verify that each titleX.structuredValueY.type has a corresponding titleX.structuredValueY.value
  def validate_title_value_for_structured_type
    @headers.each do |header|
      next unless (match = header&.match(/\Atitle(\d+)\.structuredValue(\d+)\.type\z/))

      expected_header = "title#{match[1]}.structuredValue#{match[2]}.value"

      next if @headers.include?(expected_header)

      @errors << "Missing title structured value for #{header}. Expected #{expected_header}."
    end
  end

  # verify that each titleX.structuredValueY.value has a corresponding titleX.structuredValueY.type
  def validate_title_type_for_structured_value
    @headers.each do |header|
      next unless (match = header&.match(/\Atitle(\d+)\.structuredValue(\d+)\.value\z/))

      expected_header = "title#{match[1]}.structuredValue#{match[2]}.type"

      next if @headers.include?(expected_header)

      @errors << "Missing title type for #{header}. Expected #{expected_header}."
    end
  end

  # verify that each titleX.type there is a corresponding titleX.value or titleX.structuredValue1.value
  def validate_title_types_and_values # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    @headers.filter_map { |header| header&.match(/\Atitle(\d+)\.type\z/) }.each do |matcher|
      title_value_header = "title#{matcher[1]}.value"
      title_structured_value_header = "title#{matcher[1]}.structuredValue1.value"
      title_type_header = "title#{matcher[1]}.type"

      next unless @headers.include?(title_value_header) || @headers.include?(title_structured_value_header)

      @csv.each do |row|
        next if row[title_type_header].blank? && row[title_structured_value_header].blank? && row[title_value_header].blank?

        @errors << "Missing title value for #{title_type_header}." if row[title_value_header].blank? && row[title_structured_value_header].blank?
      end
    end
  end

  # verify that for each titleX.structuredValueY.type there is a corresponding titleX.structuredValueY.value
  def validate_structured_title_types_and_values # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    @headers.filter_map { |header| header&.match(/\Atitle(\d+)\.structuredValue(\d+)\.type\z/) }.each do |matcher|
      title_structured_value_header = "title#{matcher[1]}.structuredValue#{matcher[2]}.value"
      title_structured_type_header = "title#{matcher[1]}.structuredValue#{matcher[2]}.type"

      next unless @headers.include?(title_structured_value_header)

      @csv.each do |row|
        next if row[title_structured_value_header].blank? && row[title_structured_type_header].blank?

        @errors << "Missing title value for #{title_structured_type_header}." if row[title_structured_value_header].blank?
        @errors << "Missing title type for #{title_structured_value_header}." if row[title_structured_type_header].blank?
      end
    end
  end

  def validate_header_paths
    invalid_headers.each do |invalid_header|
      @errors << "Column header invalid: #{invalid_header}"
    end
  end

  def validate_druid_headers
    @errors << 'Druid column not found.' if @headers.exclude?('druid')
  end

  def validate_druid_rows
    duplicate_druids.each do |druid|
      @errors << "Duplicate druids: The druid \"#{druid}\" should occur only once."
    end
    @csv.each.with_index(2) do |row, i|
      @errors << "Missing druid: No druid present in row #{i}." if row['druid'].blank?
    end
  end

  private

  def title_value_header?
    @headers.include?('title1.value')
  end

  def title_structured_value_header?
    @headers.include?('title1.structuredValue1.value')
  end

  def title_parallel_value_header?
    @headers.include?('title1.parallelValue1.value') || @headers.include?('title1.parallelValue1.structuredValue1.value')
  end

  def valid_title_type?(type)
    Cocina::Models::Mapping::FromMods::Title::TYPES.value?(type)
  end

  def duplicate_headers
    @headers.group_by { |e| e }.filter { |_k, v| v.many? }.keys
  end

  def duplicate_druids
    @csv.map { |row| row['druid'] }.group_by { |e| e }.filter { |_k, v| v.many? }.keys
  end

  def invalid_headers
    # The source_id is only for user reference, and we already validate the druid column is present in bulk jobs
    @headers.excluding('source_id', 'druid').filter_map do |header|
      if header
        split_address = header.scan(/[[:alpha:]]+|[[:digit:]]+/)
                              .map { |item| /\d+/.match?(item) ? item.to_i - 1 : item.to_sym }
        next if resolve_address(Cocina::Models::Description, split_address)

        header
      else
        '(empty string)'
      end
    end
  end

  def resolve_address(root, address)
    (first, *rest) = address
    node = root.schema.find { |key| key.name == first }
    return false unless node

    type = find_type(node)

    if type.respond_to?(:member) # an array
      return false unless rest.shift.is_a? Integer

      type = type.member
    end

    return true if rest.empty?

    # error if not a Cocina model class
    return false if type.is_a?(Dry::Types::AnyClass)

    resolve_address(type, rest)
  end

  def find_type(node)
    type = node.type
    type = type.type if type.default? # Unwrap default type
    case type
    when Dry::Types::Constrained
      type.type # Unwrap constrained type
    when Dry::Types::Sum::Constrained
      type.right # Unwrap nillable type
    else
      type
    end
  end
end
