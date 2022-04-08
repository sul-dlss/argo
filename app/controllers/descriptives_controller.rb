# frozen_string_literal: true

# Download the CSV descriptive metadata
class DescriptivesController < ApplicationController
  before_action :load_and_authorize_cocina

  # Display the form for uploading the descriptive metadata spreadsheet
  def new; end

  # Handle upload of the spreadsheet
  def create
    csv = CSV.read(params[:data].tempfile, headers: true)
    updated_description = DescriptionImport.import(description: @cocina.description, csv: csv)
    if updated_description.success?
      begin
        Repository.store(@cocina.new(description: updated_description.value!))
        redirect_to solr_document_path(@cocina.externalIdentifier),
                    status: :see_other,
                    notice: 'Descriptive metadata has been updated.'
      rescue Dor::Services::Client::UnexpectedResponse => e
        @error = "unexpected response from dor-services-app: #{e.message}"
        render :new, status: :unprocessable_entity
      end
    else
      @error = "There was a problem processing the spreadsheet: #{updated_description.failure}"
      render :new, status: :unprocessable_entity
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

  def load_and_authorize_cocina
    @cocina = Repository.find(params[:item_id])
    authorize! :manage_item, @cocina
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
