# frozen_string_literal: true

# It's not possible to add a new file without going through the accessioning process.
# So an upload CSV that lists a file not already present should be rejected.
# At present, the CSV update only supports changing settings,
# changing the order of resources, or removing content.
class StructureUpdater
  include Dry::Monads[:result]

  # @return [Maybe] success if there are no problems
  def self.from_csv(model, csv)
    new(model, csv).from_csv
  end

  def initialize(model, csv)
    @model = model
    @csv = CSV.new(csv, headers: true)
    @errors = []
  end

  attr_reader :model, :csv, :errors

  # @return [Bool] true if there are no problems
  def validate # rubocop:disable Naming/PredicateMethod
    @errors = []
    csv.each.with_index(2) do |row, index|
      if invalid_resource_type?(row)
        errors << "On row #{index} found \"#{row['resource_type']}\", which is not a valid resource type"
      end
      unless existing_file?(row)
        errors << "On row #{index} found #{row['filename']}, which appears to be a new file"
        next
      end
      if invalid_preservation_change?(row)
        errors << "On row #{index} found #{row['filename']}, which changed preserve from no to yes, which is not supported"
      end
      if invalid_location_rights?(row)
        errors << "On row #{index} found #{row['filename']}, which set view or download rights to location-based but did not specify a location"
      end
    end
    csv.rewind
    errors.empty?
  end

  # Ensure all files in the csv are present in the existing object
  def existing_file?(row)
    existing_files_by_filename.key?(row['filename'])
  end

  # Ensure no existing files change preserve from no to yes
  def invalid_preservation_change?(row)
    existing_files_by_filename[row['filename']].administrative.sdrPreserve == false && row['preserve'] == 'yes'
  end

  # Ensure no existing files set location-based access without specifying a location
  def invalid_location_rights?(row)
    [row['rights_view'], row['rights_download']].include?('location-based') && row['rights_location'].blank?
  end

  # Ensure all supplied resource types are valid
  def invalid_resource_type?(row)
    !Cocina::Models::FileSetType.properties.key?(row['resource_type'].to_sym)
  end

  def existing_files_by_filename
    @existing_files_by_filename ||= Array(model.structural&.contains).each_with_object({}) do |file_set, hash|
      file_set.structural.contains.each do |file|
        hash[file.filename] = file
      end
    end
  end

  def update_file(existing_file, row)
    attributes = {
      label: row['file_label'] || '',
      hasMimeType: row['mimetype'],
      use: row['role'],
      languageTag: row['file_language'],
      sdrGeneratedText: ActiveModel::Type::Boolean.new.cast(row['sdr_generated_text']) || false,
      correctedForAccessibility: ActiveModel::Type::Boolean.new.cast(row['corrected_for_accessibility']) || false,
      administrative: existing_file.administrative.new(
        publish: row['publish'] == 'yes',
        shelve: row['shelve'] == 'yes',
        sdrPreserve: row['preserve'] == 'yes'
      ),
      access: existing_file.access.class.new(
        {
          view: row['rights_view'],
          download: row['rights_download'],
          location: row['rights_location'],
          # stanford/none required controlledDigitalLending set to false. All others should omit.
          controlledDigitalLending: row['rights_view'] == 'stanford' && row['rights_download'] == 'none' ? false : nil
        }.compact
      )
    }

    existing_file.new(**attributes)
  end

  # @return [Maybe] success if there are no problems
  def from_csv
    return Failure(errors) unless validate

    fileset_attributes = {}
    # Which files go in which filesets
    files_by_fileset = csv.each_with_object({}) do |row, hash|
      hash[row['sequence']] ||= []
      fileset_attributes[row['sequence']] = { label: row['resource_label'] || '', type: type(row['resource_type']) }
      hash[row['sequence']] << update_file(existing_files_by_filename[row['filename']], row)
    end

    contains = files_by_fileset.keys.map do |sequence|
      fileset = fileset_for(sequence.to_i, files_by_fileset[sequence].first.label)
      attributes = fileset_attributes[sequence]
                   .merge(structural: { contains: files_by_fileset[sequence] })
      fileset.new(**attributes)
    end
    Success(model.structural.new(contains:))
  end

  FILESET_NAMESPACE = 'https://cocina.sul.stanford.edu/fileset/'

  # @param [Integer] sequence is the index of the fileset in the import
  # @param [String] label the label to inject for a new fileset
  def fileset_for(sequence, label)
    model.structural.contains[sequence - 1].presence ||
      Cocina::Models::FileSet.new(externalIdentifier: "#{FILESET_NAMESPACE}#{SecureRandom.uuid}",
                                  type: Cocina::Models::FileSetType.file,
                                  label:,
                                  version: 1)
  end

  # Change the short resource type into a url
  def type(resource_type)
    Cocina::Models::FileSetType.properties[resource_type.to_sym]
  end
end
