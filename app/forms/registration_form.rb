# frozen_string_literal: true

# This models the values set from the registration form
class RegistrationForm < Reform::Form
  class VirtualModel < Hash
    def persisted?
      false
    end
  end

  # standard, business, lane (matches allowed patterns in cocina-models)
  VALID_BARCODE_REGEX = /\A(36105[0-9]{9}|2050[0-9]{7}|245[0-9]{8}|[0-9]+-[0-9]+)\z/

  include HasViewAccessWithCdl

  property :current_user, virtual: true
  property :admin_policy, virtual: true
  property :collection, virtual: true

  property :workflow_id, virtual: true
  property :content_type, virtual: true
  property :viewing_direction, virtual: true
  property :project, virtual: true

  collection :tags, populate_if_empty: VirtualModel, virtual: true, save: false, skip_if: :all_blank,
    prepopulator: ->(*) { (6 - tags.count).times { tags << VirtualModel.new } } do
    property :name, virtual: true
    validates :name, allow_blank: true, format: {with: /.+( : .+)+/, message: "must include the pattern:

[term] : [term]

It's legal to have more than one colon in a hierarchy, but at least one colon is required."}
  end

  collection :items, populate_if_empty: VirtualModel, virtual: true, save: false, skip_if: :all_blank,
    prepopulator: ->(*) { (1 - items.count).times { items << VirtualModel.new } } do
    property :source_id, virtual: true
    property :catalog_record_id, virtual: true
    property :label, virtual: true
    property :barcode, virtual: true
    validates :source_id, format: {with: /\A.+:.+\z/, message: "ID is invalid"}
    validates :barcode, allow_blank: true, format: {with: VALID_BARCODE_REGEX, message: "is invalid"}
    validates_each :catalog_record_id do |record, attr, value|
      next if value.blank?

      if Settings.ils_cutover_in_progress
        record.errors.add(attr, "must be blank")
      elsif !value.match?(Regexp.new(CatalogRecordId.pattern_string))
        record.errors.add(attr, "is invalid")
      end
    end
  end

  def persisted?
    false
  end

  attr_reader :created

  def save_model
    statuses = save_items
    if statuses.all?(&:success?)
      @created = statuses.map(&:value!)
      return true
    end

    statuses.filter(&:failure?).map(&:failure).each { |error| errors.add(:save, error.message) }
    false
  end

  def save_items
    tags_with_user = tags.map(&:name) + [registered_by_tag]

    items.map do |item|
      request_model = cocina_model(item) # might raise Cocina::Models::ValidationError
      RegistrationService.register(model: request_model, workflow: workflow_id, tags: tags_with_user)
    end
  end

  def registered_by_tag
    "Registered By : #{current_user.login}"
  end

  # @raise [Cocina::Models::ValidationError]
  def cocina_model(item)
    model_params = {
      type: content_type,
      label: item.label,
      version: 1,
      administrative:,
      identification: identification(item),
      structural:,
      access:
    }

    Cocina::Models::RequestDRO.new(model_params)
  end

  # TODO: This same code is in the ItemChangeSet
  def access
    {
      view: view_access,
      download: download_access,
      location: access_location,
      controlledDigitalLending: ::ActiveModel::Type::Boolean.new.cast(controlled_digital_lending)
    }.tap do |access_params|
      access_params[:download] = "none" if %w[dark citation-only].include?(access_params[:view])
    end.compact_blank
  end

  def administrative
    {
      hasAdminPolicy: admin_policy,
      partOfProject: project
    }.compact_blank
  end

  def identification(item)
    {
      sourceId: item.source_id,
      catalogLinks: catalog_links(item),
      barcode: item.barcode
    }.compact_blank
  end

  def structural
    structural = {}
    structural[:isMemberOf] = [collection] if collection.present?
    structural[:hasMemberOrders] = [{viewingDirection: viewing_direction}] if viewing_direction.present?
    structural
  end

  def catalog_links(item)
    return [] if item.catalog_record_id.blank?

    [{catalog: CatalogRecordId.type, catalogRecordId: item.catalog_record_id, refresh: true}]
  end
end
