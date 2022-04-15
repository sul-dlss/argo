# frozen_string_literal: true

# Download the CSV descriptive metadata
class DescriptivesController < ApplicationController
  load_and_authorize_resource :cocina, parent: false, class: 'Repository', id_param: 'item_id'

  # Display the form for uploading the descriptive metadata spreadsheet
  def edit; end

  # Handle upload of the spreadsheet
  def update
    csv = CSV.read(params[:data].tempfile, headers: true)
    validator = DescriptionValidator.new(csv)
    if validator.valid?
      mapping_result = DescriptionImport.import(csv_row: csv.first)
      mapping_result.either(->(description) { convert_metdata_success(description: description) },
                            ->(error) { convert_metadata_fail(error) })
    else
      @errors = validator.errors
      render :edit, status: :unprocessable_entity
    end
  end

  # Handle download of the spreadsheet
  def show
    respond_to do |format|
      format.csv do
        filename = "descriptive-#{Druid.new(@cocina).without_namespace}.csv"
        send_data create_csv, filename: filename
      end
    end
  end

  private

  def display_error(error)
    @errors = [error]
    render :edit, status: :unprocessable_entity
  end

  def convert_metdata_success(description:)
    CocinaValidator.validate(@cocina, description: description).either(
      lambda { |valid_model|
        Repository.store(valid_model)
        redirect_to solr_document_path(@cocina.externalIdentifier),
                    status: :see_other,
                    notice: 'Descriptive metadata has been updated.'
      },
      ->(message) { display_error(message) }
    )
  rescue Dor::Services::Client::UnexpectedResponse => e
    display_error("unexpected response from dor-services-app: #{e.message}")
  end

  def convert_metadata_fail(failure)
    display_error("There was a problem processing the spreadsheet: #{failure}")
  end

  def create_csv
    description = DescriptionExport.export(source_id: @cocina.identification.sourceId,
                                           description: @cocina.description)
    headers = DescriptionHeaders.create(headers: description.keys)
    CSV.generate(write_headers: true, headers: headers) do |body|
      body << description.values_at(*headers)
    end
  end
end
