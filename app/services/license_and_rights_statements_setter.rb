# frozen_string_literal: true

# Sets the license and rights statements (copyright, use, and reproduction statements)
class LicenseAndRightsStatementsSetter
  # @param [Ability] ability ability representing current user and perms
  # @param [String] druid a druid identifier
  # @param [String] copyright copyright statement text
  # @param [String] license license code # TODO: Replace with URI
  # @param [String] use_statement use statement text
  # @raise [Dor::Services::Client::UnexpectedResponse] when dor-services-app barfs for some reason
  # @raise [Dor::Services::Client::NotFoundResponse] when dor-services-app cannot find the given object ID
  # @raise [RuntimeError] when given identifer does not correspond to an item or collection, when given
  #                       ability lacks manage_item permission, or when an underlying exception is raised
  # @return [Cocina::Models::Collection,Cocina::Models::DRO] the cocina object with updates applied
  def self.set(ability:, druid:, copyright: nil, license: nil, use_statement: nil)
    new(ability: ability,
        druid: druid,
        copyright: copyright,
        license: license,
        use_statement: use_statement)
      .set
  end

  # @param [Ability] ability ability representing current user and perms
  # @param [String] druid a druid identifier
  # @param [String] copyright copyright statement text
  # @param [String] license license code # TODO: Replace with URI
  # @param [String] use_statement use statement text
  def initialize(ability:, druid:, copyright: nil, license: nil, use_statement: nil)
    @ability = ability
    @druid = druid
    @copyright = copyright
    @license = license
    @use_statement = use_statement
  end

  # @raise [Dor::Services::Client::UnexpectedResponse] when dor-services-app barfs for some reason
  # @raise [Dor::Services::Client::NotFoundResponse] when dor-services-app cannot find the given object ID
  # @raise [RuntimeError] when given identifer does not correspond to an item or collection, when given
  #                       ability lacks manage_item permission, or when an underlying exception is raised
  # @return [Cocina::Models::Collection,Cocina::Models::DRO,nil] the cocina object with updates applied or `nil` if no changes
  def set
    raise "#{druid} cannot be changed by #{ability.current_user}" unless ability.can?(:manage_item, cocina_object)
    raise "#{druid} is not an item or collection (#{cocina_object.type})" unless cocina_object.dro? || cocina_object.collection?
    return unless change_set.changed?

    open_new_version! unless state_service.allows_modification?

    change_set.save
  end

  private

  attr_reader :ability, :druid, :copyright, :license, :use_statement

  def open_new_version!
    raise "unable to open new version for #{druid}" unless openable?

    VersionService.open(identifier: cocina_object.externalIdentifier,
                        significance: 'minor',
                        description: new_version_message,
                        opening_user_name: ability.current_user.to_s)
  end

  def openable?
    DorObjectWorkflowStatus.new(druid, version: cocina_object.version).can_open_version?
  end

  def state_service
    StateService.new(cocina_object)
  end

  def change_set
    args = {}
    args[:license] = license unless license.nil?
    args[:copyright] = copyright unless copyright.nil?
    args[:use_statement] = use_statement unless use_statement.nil?
    change_set_class.new(cocina_object).tap do |change_set|
      change_set.validate(args)
    end
  end

  def change_set_class
    case cocina_object
    when Cocina::Models::DRO
      ItemChangeSet
    when Cocina::Models::Collection
      CollectionChangeSet
    end
  end

  def cocina_object
    Dor::Services::Client.object(druid).find
  end

  def new_version_message
    'updated license, copyright statement, and/or use and reproduction statement'
  end
end
