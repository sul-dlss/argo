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

  collection :tickets, populate_if_empty: VirtualModel, virtual: true, save: false, skip_if: :all_blank,
                       prepopulator: ->(*) { (2 - tickets.count).times { tickets << VirtualModel.new } } do
    property :name, virtual: true
  end

  property :csv_file, virtual: true

  validate :csv_file_validation

  def persisted?
    false
  end

  attr_reader :created

  def save_model # rubocop:disable Naming/PredicateMethod
    bulk_action = BulkAction.new(user: current_user, action_type: 'RegisterDruidsJob')

    if bulk_action.save
      bulk_action.enqueue_job(job_params)
      true
    else
      false
    end
  end

  def ticket_tags
    tickets.filter_map { |ticket| "Ticket : #{ticket.name}" if ticket.name.present? }
  end

  def job_params
    {
      administrative_policy_object: admin_policy,
      collection: collection.presence,
      initial_workflow: workflow_id,
      content_type:,
      reading_order: viewing_direction,
      project_name: project.presence,
      tags: tags.map(&:name) + ticket_tags + [registered_by_tag],
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

  def csv_file_validation # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    validator = CsvUploadValidator.new(csv: job_csv, required_headers: 'source_id')
    errors.add(:csv_file, validator.errors.join(' ')) unless validator.valid? do |csv|
      # Validates that data is present for one of the required columns.
      if one_of_data_headers.none? { |header| csv.headers.include?(header) }
        ["missing header. One of these must be provided: #{one_of_data_headers.join(', ')}"]
      elsif csv.any? { |row| one_of_data_headers.none? { |header| row[header].present? } }
        ["missing data. For each row, one of these must be provided: #{one_of_data_headers.join(', ')}"]
      else
        []
      end
    end
  rescue CSV::MalformedCSVError => e
    errors.add :csv_file, "is invalid: #{e.message}"
  end

  def one_of_data_headers
    @one_of_data_headers ||= ['label', CatalogRecordId.csv_header]
  end
end
