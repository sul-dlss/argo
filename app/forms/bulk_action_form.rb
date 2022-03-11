# frozen_string_literal: true

# This models the values set from the bulk action form
class BulkActionForm < BaseForm
  VIRTUAL_PROPERTIES = %i[
    add_workflow manage_release set_governing_apo
    set_catkeys_and_barcodes set_catkeys_and_barcodes_csv
    set_source_ids_csv prepare register_druids
    create_virtual_objects import_tags
    set_license_and_rights_statements manage_embargo
    set_content_type set_collection
  ].freeze

  def initialize(model, groups:)
    super(model)
    @groups = groups
  end

  def save
    sync
    BulkActionPersister.persist(self)
  end

  def sync
    model.attributes = params.except(:pids, :groups, *VIRTUAL_PROPERTIES)
    @pids = pids_with_prefix

    VIRTUAL_PROPERTIES.each do |prop|
      public_send("#{prop}=".to_sym, params[prop])
    end
  end

  attr_accessor :groups, :pids, *VIRTUAL_PROPERTIES

  delegate :action_type, :description, to: :model

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def csv_as_string
    csv_file = create_virtual_objects&.fetch(:csv_file) ||
               register_druids&.fetch(:csv_file) ||
               import_tags&.fetch(:csv_file) ||
               set_catkeys_and_barcodes_csv&.fetch(:csv_file) ||
               manage_embargo&.fetch(:csv_file) ||
               set_source_ids_csv&.fetch(:csv_file)

    # Short-circuit if no csv file
    return unless csv_file

    File.read(csv_file.path)
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def license_options
    [['-- No license --', '']] +
      options_for_use_license_type
  end

  private

  # add druid: prefix to list of pids if it doesn't have it yet
  def pids_with_prefix
    pids = params[:pids]
    return pids if pids.blank?

    pids.split.flatten.map { |pid| pid.start_with?('druid:') ? pid : "druid:#{pid}" }.join("\n")
  end

  def options_for_use_license_type
    # We use `#filter_map` here to remove nils from the options block (for unused deprecated licenses)
    Constants::LICENSE_OPTIONS.filter_map do |attributes|
      next if attributes.key?(:deprecation_warning)

      [attributes.fetch(:label), attributes.fetch(:uri)]
    end
  end
end
