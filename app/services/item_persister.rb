# frozen_string_literal: true

# Writes updates Cocina Models
class ItemPersister # rubocop:disable Metrics/ClassLength
  # @param [Cocina::Models::DRO] model the orignal state of the model
  # @param [Item] change_set the values to update.
  # @return [Cocina::Models::DRO] the model with updates applied
  def self.update(model, change_set)
    new(model, change_set).update
  end

  def initialize(model, change_set)
    @model = model
    @change_set = change_set
  end

  # @raises [Dor::Services::Client::BadRequestError] when the server doesn't accept the request
  def update
    updated_model = update_type(model)
                    .then { |updated| update_structural(updated) }
                    .then { |updated| update_identification(updated) }
                    .then { |updated| updated_administrative(updated) }
                    .then { |updated| updated_access(updated) }
    object_client.update(params: updated_model)
  end

  private

  # The map between the change set fields and the Cocina field names
  ACCESS_FIELDS = {
    copyright: :copyright,
    license: :license,
    use_statement: :useAndReproductionStatement,
    view_access: :view,
    download_access: :download,
    access_location: :location,
    controlled_digital_lending: :controlledDigitalLending
  }.freeze

  attr_reader :model, :change_set

  delegate :admin_policy_id, :barcode, :catkey, :collection_ids,
           :embargo, :source_id,
           *ACCESS_FIELDS.keys,
           :collection_ids_changed?, :source_id_changed?,
           :catkeys_changed?, :barcode_changed?, :admin_policy_id_changed?,
           :copyright_changed?, :license_changed?, :use_statement_changed?,
           :embargo_changed?, :file_sets_changed?, :members_changed?,
           :file_sets, :members,
           :view_access_changed?, :download_access_changed?,
           :access_location_changed?, :controlled_digital_lending_changed?,
           :type, :type_changed?, to: :change_set

  def object_client
    Dor::Services::Client.object(model.externalIdentifier)
  end

  def update_type(updated)
    return updated unless type_changed?

    updated.new(type: type)
  end

  def updated_administrative(updated)
    return updated unless admin_policy_id_changed?

    updated_administrative = updated.administrative.new(hasAdminPolicy: admin_policy_id)
    updated.new(administrative: updated_administrative)
  end

  def update_structural(updated)
    return updated unless structural_changed?

    updated_structural = updated.structural.new(isMemberOf: Array(collection_ids))
    updated_structural = update_file_sets(updated_structural) if file_sets_changed?
    if members_changed?
      orders = updated_structural.hasMemberOrders || []
      first_order = orders.first || Cocina::Models::Sequence
      new_order = first_order.new(members: members)
      updated_structural = updated_structural.new(hasMemberOrders: [new_order])
    end

    updated.new(structural: updated_structural)
  end

  def update_file_sets(updated_structural)
    contains = file_sets.map do |file_set|
      new_files = file_set.files.map do |file|
        update_file(file)
      end
      new_struct = file_set.model.structural.new(contains: new_files)
      file_set.model.new(structural: new_struct)
    end
    updated_structural.new(contains: contains)
  end

  def update_file(file)
    new_access = file.model.access.new(view: file.view_access, download: file.download_access, location: file.access_location,
                                       controlledDigitalLending: file.controlled_digital_lending)
    new_file = file.model.new(access: new_access)
    new_file = new_file.new(filename: file.filename) if file.filename_changed?

    if file.administrative_changed?
      admin = file.model.administrative
      admin = admin.new(publish: file.publish) if file.publish_changed?
      admin = admin.new(shelve: file.shelve) if file.shelve_changed?
      admin = admin.new(sdrPreserve: file.preserve) if file.preserve_changed?
      new_file = new_file.new(administrative: admin)
    end
    new_file
  end

  def access_changed?
    embargo_changed? || ACCESS_FIELDS.keys.any? { |field| public_send("#{field}_changed?".to_sym) }
  end

  def identification_changed?
    source_id_changed? || catkeys_changed? || barcode_changed?
  end

  def structural_changed?
    collection_ids_changed? || file_sets_changed? || members_changed?
  end

  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  def updated_access(updated)
    return updated unless access_changed?

    access_properties = {}
    access_properties[:copyright] = copyright.presence if copyright_changed?
    access_properties[:license] = license.presence if license_changed?
    access_properties[:useAndReproductionStatement] = use_statement if use_statement_changed?
    access_properties[:embargo] = embargo_props if embargo_changed?
    access_properties[:view] = view_access if view_access_changed?
    access_properties[:download] = download_access if download_access_changed?
    access_properties[:location] = access_location if access_location_changed?
    access_properties[:controlledDigitalLending] = controlled_digital_lending if controlled_digital_lending_changed?
    updated.new(access: updated.access.new(access_properties))
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity

  def embargo_props
    embargo = change_set.embargo
    updated_model = embargo.model
    updated_model = updated_model.new(releaseDate: embargo.release_date) if embargo.release_date_changed?
    updated_model = updated_model.new(view: embargo.view_access) if embargo.view_access_changed?
    updated_model = updated_model.new(download: embargo.download_access) if embargo.download_access_changed?
    updated_model = updated_model.new(accessLocation: embargo.accessLocation) if embargo.access_location_changed?

    updated_model
  end

  def update_identification(updated)
    return updated unless identification_changed?

    identification_props = updated.identification&.to_h || {}
    identification_props[:sourceId] = source_id if source_id_changed?
    identification_props[:barcode] = barcode.presence if barcode_changed?
    identification_props[:catalogLinks] = Catkey.serialize(model, catkey) if catkeys_changed?
    updated.new(identification: identification_props.presence)
  end
end
