# frozen_string_literal: true

# Represents a set of changes to an item.
class ItemChangeSet < Reform::Form
  property :admin_policy_id, virtual: true
  property :catkey, virtual: true
  property :collection_ids, virtual: true
  property :copyright_statement, virtual: true
  property :embargo_release_date, virtual: true
  property :license, virtual: true
  property :source_id, virtual: true
  property :use_statement, virtual: true
  property :barcode, virtual: true

  # def initialize(model)#(model: nil)
  #   # @cocina_item = model
  #   # @changes = {}
  #   # populate_from_model if model
  #   # yield self if block_given?
  #   byebug
  #   super
  # end

  def self.model_name
    Struct.new(:param_key, :route_key, :i18n_key, :name).new('item', 'item', 'item', 'Item')
  end

  # needed for generating the update route
  def to_key
    Array(@cocina_item&.externalIdentifier)
  end

  # :       def setup_properties!(options)
  # => 22:         schema.each { |dfn| setup_property!(dfn, options) }
  #    23:       end
  def setup_properties!(_options)
    self.catkey = model.identification&.catalogLinks&.find { |link| link.catalog == 'symphony' }&.catalogRecordId
  end

  def save_model
    ItemChangeSetPersister.update(model, self)
  end

  # PROPERTIES.each do |property|
  #   define_method(property) do
  #     @changes[property]
  #   end
  #
  #   define_method("#{property}_changed?") do
  #     @changes.key?(property)
  #   end
  #
  #   define_method("#{property}=") do |value|
  #     @changes[property] = value
  #   end
  # end

  # Allows collaborators to ask if the change set includes *any* changes
  # def changed?
  #   @changes.any?
  # end

  # def ==(other)
  #   PROPERTIES.each do |property|
  #     return false if public_send(property) != other.public_send(property)
  #   end
  #   true
  # end
end
