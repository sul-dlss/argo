# frozen_string_literal: true

# Handles HTTP interaction that allows management of bulk jobs for an APO
class BulkJobsController < ApplicationController
  # Generates the index page for a given DRUID's past bulk metadata upload jobs.
  def index
    params[:apo_id] = 'druid:' + params[:apo_id] unless params[:apo_id].include? 'druid'
    @obj = Dor.find params[:apo_id]

    authorize! :view_metadata, @obj
    @document = find(params[:apo_id])
    @bulk_jobs = load_bulk_jobs(params[:apo_id])
    @buttons_presenter = ButtonsPresenter.new(
      ability: current_ability,
      solr_document: @document,
      object: @obj
    )
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
        if File.exist?(@user_log.csv_file)
          send_file(@user_log.csv_file, type: 'text/csv')
        else
          render :nothing, status: :not_found
          # Display error message and log the error
        end
      end
      format.xml do
        if File.exist?(@user_log.desc_metadata_xml_file)
          send_file(@user_log.desc_metadata_xml_file, type: 'application/xml')
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
    directory_to_delete = File.join(Settings.bulk_metadata.directory, params[:dir])
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
