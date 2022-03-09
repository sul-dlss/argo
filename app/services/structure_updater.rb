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
  def validate
    @errors = []
    # 1. Ensure all files in the csv are present in the existing object
    csv.each.with_index(2) do |row, index|
      errors << "On row #{index} found #{row['filename']}, which appears to be a new file" unless existing_files_by_filename.key?(row['filename'])
    end
    csv.rewind
    errors.empty?
  end

  def existing_files_by_filename
    @existing_files_by_filename ||= Array(model.structural.contains).each_with_object({}) do |file_set, hash|
      file_set.structural.contains.each do |file|
        hash[file.filename] = file
      end
    end
  end

  def update_file(existing_file, row)
    attributes = {
      hasMimeType: row['mimetype'],
      label: row['file_label'],
      administrative: existing_file.administrative.new(
        publish: row['publish'] == 'yes',
        shelve: row['shelve'] == 'yes',
        sdrPreserve: row['preserve'] == 'yes'
      ),
      access: existing_file.access.new(
        view: row['rights_access'],
        download: row['rights_download']
      )
    }
    attributes[:use] = row['role'] if row['role'] # nil is not permitted
    existing_file.new(**attributes)
  end

  # @return [Maybe] success if there are no problems
  def from_csv
    return Failure(errors) unless validate

    fileset_attributes = {}
    # Which files go in which filesets
    files_by_fileset = csv.each_with_object({}) do |row, hash|
      hash[row['sequence']] ||= []
      fileset_attributes[row['sequence']] = { label: row['resource_label'], type: type(row['resource_type']) }
      hash[row['sequence']] << update_file(existing_files_by_filename[row['filename']], row)
    end

    contains = files_by_fileset.keys.map do |sequence|
      # Find the existing fileset
      existing_fileset = model.structural.contains[sequence.to_i - 1]
      attributes = fileset_attributes[sequence]
                   .merge(structural: { contains: files_by_fileset[sequence] })
      existing_fileset.new(**attributes)
    end

    Success(model.structural.new(contains: contains))
  end

  # Change the short resource type into a url
  def type(resource_type)
    Cocina::Models::FileSetType.public_send(resource_type)
  end
end
