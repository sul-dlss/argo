# frozen_string_literal: true

# Download the CSV descriptive metadata
class DescriptivesController < ApplicationController
  before_action :load_and_authorize_resource

  # Display the form for uploading the descriptive metadata spreadsheet
  def new; end

  # Handle upload of the spreadsheet
  def create
    csv = CSV.read(params[:data].tempfile, headers: true)
    mapping_result = DescriptionImport.import(csv_row: csv.first)
    mapping_result.either(->(description) { convert_metdata_success(description: description) },
                          ->(error) { convert_metadata_fail(error) })
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

  def convert_metdata_success(description:)
    Repository.store(@cocina.new(description: description))
    redirect_to solr_document_path(@cocina.externalIdentifier),
                status: :see_other,
                notice: 'Descriptive metadata has been updated.'
  rescue Dor::Services::Client::UnexpectedResponse => e
    @error = "unexpected response from dor-services-app: #{e.message}"
    render :new, status: :unprocessable_entity
  end

  def convert_metadata_fail(failure)
    @error = "There was a problem processing the spreadsheet: #{failure}"
    render :new, status: :unprocessable_entity
  end

  def create_csv
    description = DescriptionExport.export(source_id: @cocina.identification.sourceId,
                                           description: @cocina.description)
    headers = ['source_id'] + (description.keys - ['source_id']).sort

    CSV.generate(write_headers: true, headers: headers) do |body|
      body << description.values_at(*headers)
    end
  end
end
