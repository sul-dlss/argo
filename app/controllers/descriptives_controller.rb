# frozen_string_literal: true

# Download the CSV descriptive metadata
class DescriptivesController < ApplicationController
  load_and_authorize_resource :cocina, parent: false, class: "Repository", id_param: "item_id"

  # Display the form for uploading the descriptive metadata spreadsheet
  def show
    respond_to do |format|
      format.csv do
        filename = "descriptive-#{Druid.new(@cocina).without_namespace}.csv"
        send_data create_csv, filename:
      end
    end
  end

  # Handle upload of the spreadsheet
  def edit
  end

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
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def display_success
    # The title as shown to the user comes from Solr (`sw_display_title_tesim`), so we re-index to ensure any change is immediately shown
    # see https://github.com/sul-dlss/argo/issues/3656
    Argo::Indexer.reindex_druid_remotely(@cocina.externalIdentifier)
    redirect_to solr_document_path(@cocina.externalIdentifier), status: :see_other, notice: "Descriptive metadata has been updated."
  end

  def display_error(messages)
    @errors = messages
    render :edit, status: :unprocessable_entity
  end

  def create_csv
    description = DescriptionExport.export(source_id: @cocina.identification.sourceId,
      description: @cocina.description)
    headers = DescriptionHeaders.create(headers: description.keys)
    CSV.generate(write_headers: true, headers: ["druid"] + headers) do |body|
      body << ([@cocina.externalIdentifier] + description.values_at(*headers))
    end
  end
end
