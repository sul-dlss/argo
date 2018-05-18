# Handles the HTTP interaction for creating bulk metadata uploads
class UploadsController < ApplicationController
  # GET /items/:item_id/uploads/new
  def new
    @obj = Dor.find params[:item_id]
  end

  # Lets the user start a bulk metadata job (i.e. upload a metadata spreadsheet/XML file).
  # POST /items/:item_id/uploads
  def create
    apo = Dor.find params[:item_id]

    directory_name = Time.zone.now.strftime('%Y_%m_%d_%H_%M_%S_%L')
    output_directory = File.join(Settings.BULK_METADATA.DIRECTORY, params[:druid], directory_name)
    temp_spreadsheet_filename = params[:spreadsheet_file].original_filename + '.' + directory_name

    # Temporary files are sometimes garbage collected before the Delayed Job is run, so make a copy and let the job delete it when it's done.
    temp_filename = make_tmp_filename(temp_spreadsheet_filename)
    FileUtils.copy(params[:spreadsheet_file].path, temp_filename)
    ModsulatorJob.perform_later(apo.id, temp_filename.to_s, output_directory, current_user.login, params[:filetypes], params[:xml_only], params[:note])

    redirect_to bulk_jobs_index_path(apo.id)
  end
end
