# frozen_string_literal: true

# Handles the HTTP interaction for creating bulk metadata uploads for an APO
class UploadsController < ApplicationController
  # GET /apos/:apo_id/uploads/new
  def new
    @obj = Dor.find params[:apo_id]
  end

  # Lets the user start a bulk metadata job (i.e. upload a metadata spreadsheet/XML file).
  # POST /apos/:apo_id/uploads
  def create
    directory_name = Time.zone.now.strftime('%Y_%m_%d_%H_%M_%S_%L')
    output_directory = File.join(Settings.BULK_METADATA.DIRECTORY, params[:druid], directory_name)
    temp_spreadsheet_filename = params[:spreadsheet_file].original_filename + '.' + directory_name

    # Temporary files are sometimes garbage collected before the Delayed Job is run, so make a copy and let the job delete it when it's done.
    temp_filename = make_tmp_filename(temp_spreadsheet_filename)
    FileUtils.copy(params[:spreadsheet_file].path, temp_filename)
    ModsulatorJob.perform_later(params[:apo_id],
                                temp_filename.to_s,
                                output_directory,
                                current_user,
                                current_user.groups,
                                params[:filetypes],
                                params[:note])

    redirect_to apo_bulk_jobs_path(params[:apo_id])
  end

  private

  def make_tmp_filename(temp_spreadsheet_filename)
    FileUtils.mkdir_p(Settings.BULK_METADATA.TEMPORARY_DIRECTORY) unless File.exist?(Settings.BULK_METADATA.TEMPORARY_DIRECTORY)
    File.join(Settings.BULK_METADATA.TEMPORARY_DIRECTORY, temp_spreadsheet_filename)
  end
end
