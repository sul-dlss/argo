# Handles HTTP interaction that allows management of bulk jobs
class BulkJobsController < ApplicationController
  # Generates the index page for a given DRUID's past bulk metadata upload jobs.
  def index
    params[:apo_id] = 'druid:' + params[:apo_id] unless params[:apo_id].include? 'druid'
    @obj = Dor.find params[:apo_id]

    authorize! :view_metadata, @obj
    @document = find(params[:apo_id])
    @bulk_jobs = load_bulk_jobs(params[:apo_id])
  end

  # GET /apos/:apo_id/bulk_jobs/:time/log(.:format)
  def show
    respond_to do |format|
      format.html do
        # Generate both the actual log messages that go in the HTML and the CSV, since both need to be ready when the table is displayed to the user
        @user_log = UserLog.new(params[:apo_id], params[:time])
        @user_log.user_log_csv
      end
      format.csv do
        csv_file = File.join(Settings.BULK_METADATA.DIRECTORY, params[:apo_id], params[:time], 'log.csv')
        if File.exist?(csv_file)
          send_file(csv_file, type: 'text/csv')
        else
          render :nothing, status: :not_found
          # Display error message and log the error
        end
      end
      format.xml do
        desc_metadata_xml_file = find_desc_metadata_file(File.join(Settings.BULK_METADATA.DIRECTORY, params[:apo_id], params[:time]))
        if File.exist?(desc_metadata_xml_file)
          send_file(desc_metadata_xml_file, type: 'application/xml')
        else
          render :nothing, status: :not_found
          # Display error message and log the error
        end
      end
    end
  end

  def status_help; end

  def help; end

  # DELETE /items/:item_id/bulk_jobs
  def delete
    @apo = params[:item_id]
    directory_to_delete = File.join(Settings.BULK_METADATA.DIRECTORY, params[:dir])
    FileUtils.remove_dir(directory_to_delete, true)
    redirect_to item_bulk_jobs_path(@apo)
  end

  def self.local_prefixes
    super + ['catalog']
  end

  private

  def find(id)
    CatalogController.new.repository.find(id).documents.first
  end

  # Given a DRUID, loads any metadata bulk upload information associated with that DRUID into a hash.
  def load_bulk_jobs(druid)
    directory_list = []
    bulk_info = []
    bulk_load_dir = File.join(Settings.BULK_METADATA.DIRECTORY, druid)

    # The metadata bulk upload processing stores its logs and other information in a very simple directory structure
    directory_list = Dir.glob("#{bulk_load_dir}/*") if File.directory?(bulk_load_dir)

    directory_list.each do |d|
      bulk_info.push(bulk_job_metadata(d))
    end

    # Sort by start time (newest first)
    sorted_info = bulk_info.sort_by { |b| b['argo.bulk_metadata.bulk_log_job_start'].to_s }
    sorted_info.reverse!
  end

  # Given a directory with bulk metadata upload information (written by ModsulatorJob), loads the job data into a hash.
  def bulk_job_metadata(dir)
    success = 0
    job_info = {}
    log_filename = File.join(dir, Settings.BULK_METADATA.LOG)
    if File.directory?(dir) && File.readable?(dir) && File.exist?(log_filename) && File.readable?(log_filename)
      File.open(log_filename, 'r') do |log_file|
        log_file.each_line do |line|
          # The log file is a very simple flat file (whitespace separated) format where the first token denotes the
          # field/type of information and the rest is the actual value.
          matched_strings = line.match(/^([^\s]+)\s+(.*)/)
          next unless matched_strings && matched_strings.length == 3
          job_info[matched_strings[1]] = matched_strings[2]
          success += 1 if matched_strings[1] == 'argo.bulk_metadata.bulk_log_job_save_success'
          job_info['error'] = 1 if UserLog::ERROR_MESSAGES.include?(matched_strings[1])
        end
        job_info['dir'] = get_leafdir(dir)
        job_info['argo.bulk_metadata.bulk_log_druids_loaded'] = success
      end
    end
    job_info
  end

  def find_desc_metadata_file(job_output_directory)
    metadata = bulk_job_metadata(job_output_directory)
    filename = metadata.fetch('argo.bulk_metadata.bulk_log_xml_filename')
    File.join(job_output_directory, filename)
  end

  def get_leafdir(directory)
    directory[Settings.BULK_METADATA.DIRECTORY.length, directory.length].sub(%r{^/+(.*)}, '\1')
  end
end
