# frozen_string_literal: true

# Download the CSV descriptive metadata
class DescriptivesController < ApplicationController
  before_action :maybe_find_cocina, only: :show
  load_and_authorize_resource :cocina, parent: false, class: 'Repository', id_param: 'item_id'

  # Display the form for uploading the descriptive metadata spreadsheet
  def show
    respond_to do |format|
      format.csv { send_data(create_csv, filename:) }
    end
  end

  # Handle upload of the spreadsheet
  def edit; end

  # Handle download of the spreadsheet
  def update
    csv = CSV.parse(CsvUploadNormalizer.read(params[:data].tempfile), headers: true)
    validator = DescriptionValidator.new(csv)
    if validator.valid?
      DescriptionImport.import(csv_row: csv.first)
                       .bind { |description| CocinaValidator.validate_and_save(@cocina, description:) }
                       .either(
                         ->(_updated) { display_success },
                         ->(messages) { display_error(messages) }
                       )
    else
      @errors = validator.errors
      render :edit, status: :unprocessable_content
    end
  rescue CSV::MalformedCSVError
    @errors = ['The file you uploaded is not a valid CSV file.']
    render :edit, status: :unprocessable_content
  end

  private

  def filename
    return "descriptive-#{Druid.new(@cocina).without_namespace}.csv" unless params.key?(:user_version_id)

    "descriptive-#{Druid.new(@cocina).without_namespace}-v#{params[:user_version_id]}.csv"
  end

  def maybe_find_cocina
    @cocina = if params.key?(:user_version_id)
                Repository.find_user_version(params[:item_id], params[:user_version_id])
              elsif params.key?(:version_id)
                Repository.find_version(params[:item_id], params[:version_id])
              end
  end

  def display_success
    # The title as shown to the user comes from Solr (`display_title_ss`), so we re-index to ensure any change is immediately shown
    # see https://github.com/sul-dlss/argo/issues/3656
    Dor::Services::Client.object(@cocina.externalIdentifier).reindex
    redirect_to solr_document_path(@cocina.externalIdentifier), status: :see_other,
                                                                notice: 'Descriptive metadata has been updated.'
  end

  def display_error(messages)
    @errors = messages
    render :edit, status: :unprocessable_content
  end

  def create_csv
    description = DescriptionExport.export(source_id: @cocina.identification.sourceId,
                                           description: @cocina.description)
    headers = DescriptionHeaders.create(headers: description.keys)
    CSV.generate(write_headers: true, headers: ['druid'] + headers) do |body|
      body << ([@cocina.externalIdentifier] + description.values_at(*headers))
    end
  end
end
