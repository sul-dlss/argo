# frozen_string_literal: true

# This models the values set from the bulk action form
class BulkActionForm < BaseForm
  VIRTUAL_PROPERTIES = %i[manage_release set_governing_apo manage_catkeys
                          prepare register_druids create_virtual_objects import_tags].freeze

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

  def csv_as_string
    csv_file = create_virtual_objects&.fetch(:csv_file) ||
               register_druids&.fetch(:csv_file) ||
               import_tags&.fetch(:csv_file)

    # Short-circuit if request is not related to creating virtual objects
    return unless csv_file

    File.read(csv_file.path)
  end

  private

  # add druid: prefix to list of pids if it doesn't have it yet
  def pids_with_prefix
    pids = params[:pids]
    return pids if pids.blank?

    pids.split.flatten.map { |pid| pid.start_with?('druid:') ? pid : "druid:#{pid}" }.join("\n")
  end
end
