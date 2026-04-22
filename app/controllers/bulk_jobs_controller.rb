# frozen_string_literal: true

# Handles HTTP interaction that allows management of bulk jobs for an APO
class BulkJobsController < ApplicationController
  include Blacklight::Searchable

  load_resource :cocina, class: 'Repository', id_param: 'apo_id', only: :index

  # Generates the index page for a given DRUID's past bulk metadata upload jobs.
  def index
    authorize! :read, @cocina

    @document = find(params[:apo_id])
    @bulk_jobs = load_bulk_jobs(params[:apo_id])
  end

  # GET /apos/:apo_id/bulk_jobs/:time/log(.:format)
  def show
    @user_log = UserLog.new(params[:apo_id], params[:time])

    respond_to do |format|
      format.html do
        # Generate both the actual log messages that go in the HTML and the CSV, since both need to be ready when the table is displayed to the user
        @user_log.create_csv_log
      end
      format.csv do
        csv_path = @user_log.csv_file
        if File.exist?(csv_path) && safe_path?(csv_path)
          send_file(csv_path, type: 'text/csv')
        else
          render :nothing, status: :not_found
          # Display error message and log the error
        end
      end
      format.xml do
        xml_path = @user_log.desc_metadata_xml_file
        if File.exist?(xml_path) && safe_path?(xml_path)
          send_file(xml_path, type: 'application/xml')
        else
          render :nothing, status: :not_found
          # Display error message and log the error
        end
      end
    end
  end

  def status_help; end

  # DELETE /apos/:apo_id/bulk_jobs
  def destroy
    @apo = params[:apo_id]
    base = File.expand_path(Settings.bulk_metadata.directory)
    directory_to_delete = File.expand_path(File.join(base, params[:dir]))
    return redirect_to apo_bulk_jobs_path(@apo), alert: 'Invalid directory.' unless directory_to_delete.start_with?(base)

    FileUtils.remove_dir(directory_to_delete, true)
    redirect_to apo_bulk_jobs_path(@apo), notice: "Bulk job for APO (#{@apo}) deleted."
  end

  def self.local_prefixes
    super + ['catalog']
  end

  private

  def find(id)
    search_service.fetch(id).last
  end

  # Given a DRUID, loads any metadata bulk upload information associated with that DRUID into a hash.
  def safe_path?(path)
    base = File.expand_path(Settings.bulk_metadata.directory)
    File.expand_path(path).start_with?(base)
  end

  def load_bulk_jobs(druid)
    directory_list = []
    bulk_info = []
    bulk_load_dir = File.join(Settings.bulk_metadata.directory, druid)

    # The metadata bulk upload processing stores its logs and other information in a very simple directory structure
    directory_list = Dir.glob("#{bulk_load_dir}/*") if File.directory?(bulk_load_dir)

    directory_list.each do |directory|
      time = directory.sub("#{bulk_load_dir}/", '')
      log = UserLog.new(druid, time)
      bulk_info.push(log.bulk_job_metadata)
    end

    # Sort by start time (newest first)
    sorted_info = bulk_info.sort_by { |b| b['argo.bulk_metadata.bulk_log_job_start'].to_s }
    sorted_info.reverse!
  end
end
