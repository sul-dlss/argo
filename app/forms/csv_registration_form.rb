# frozen_string_literal: true

# This models the values set from the registration form when submitting a CSV.
class CsvRegistrationForm < Reform::Form
  class VirtualModel < Hash
    def persisted?
      false
    end
  end

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
    validates :name, allow_blank: true, format: { with: /.+( : .+)+/, message: "must include the pattern:

[term] : [term]

It's legal to have more than one colon in a hierarchy, but at least one colon is required." }
  end

  property :csv_file, virtual: true

  validate :csv_file_validation

  def persisted?
    false
  end

  attr_reader :created

  def save_model
    bulk_action = BulkAction.new(user: current_user, action_type: 'RegisterDruidsJob')

    if bulk_action.save
      bulk_action.enqueue_job(job_params)
      true
    else
      false
    end
  end

  def job_params
    {
      administrative_policy_object: admin_policy,
      collection: collection.presence,
      initial_workflow: workflow_id,
      content_type:,
      reading_order: viewing_direction,
      project_name: project.presence,
      tags: tags.map(&:name) + [registered_by_tag],
      groups: current_user.groups,
      csv_file: job_csv
    }.merge(access_params).compact
  end

  # Note that similar code is in the ItemChangeSet
  def access_params
    {
      rights_view: view_access,
      rights_download: download_access,
      rights_location: access_location,
      rights_controlledDigitalLending: ::ActiveModel::Type::Boolean.new.cast(controlled_digital_lending)
    }.tap do |access_params|
      access_params[:rights_download] = 'none' if %w[dark citation-only].include?(access_params[:rights_view])
    end.compact_blank
  end

  def registered_by_tag
    "Registered By : #{current_user.login}"
  end

  def job_csv
    @job_csv ||= CsvUploadNormalizer.read(csv_file.path)
  end

  def header_validators
    [
      CsvUploadValidator::RequiredHeaderValidator.new(headers: ['source_id']),
      CsvUploadValidator::OrRequiredDataValidator.new(headers: ['label', CatalogRecordId.csv_header])
    ]
  end

  def csv_file_validation
    validator = CsvUploadValidator.new(csv: job_csv, header_validators:)
    errors.add(:csv_file, validator.errors.join(' ')) unless validator.valid?
  rescue CSV::MalformedCSVError => e
    errors.add :csv_file, "is invalid: #{e.message}"
  end
end
