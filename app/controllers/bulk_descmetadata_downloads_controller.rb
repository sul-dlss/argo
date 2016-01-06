class BulkDescmetadataDownloadsController < ApplicationController
  before_action :set_bulk_descmetadata_download, only: [:show, :edit, :update, :destroy]

  # GET /bulk_descmetadata_downloads
  def index
    @bulk_descmetadata_downloads = BulkDescmetadataDownload.all
  end

  # GET /bulk_descmetadata_downloads/1
  def show
  end

  # GET /bulk_descmetadata_downloads/new
  def new
    @bulk_descmetadata_download = BulkDescmetadataDownload.new
    @druid_list = Array.new('druid:hj185vb7593', 'druid:kv840rx2720', 'druid:pv820dk6668', 'druid:qq613vj0238', 'druid:rn653dy9317', 'druid:xb482bw3979')
    @bulk_action = BulkAction.create(current_user)
  end

  # GET /bulk_descmetadata_downloads/1/edit
  def edit
  end

  # POST /bulk_descmetadata_downloads
  def create
    @bulk_descmetadata_download = BulkDescmetadataDownload.new(bulk_descmetadata_download_params)

    if @bulk_descmetadata_download.save
      redirect_to @bulk_descmetadata_download, notice: 'Bulk descmetadata download was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /bulk_descmetadata_downloads/1
  def update
    if @bulk_descmetadata_download.update(bulk_descmetadata_download_params)
      redirect_to @bulk_descmetadata_download, notice: 'Bulk descmetadata download was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /bulk_descmetadata_downloads/1
  def destroy
    @bulk_descmetadata_download.destroy
    redirect_to bulk_descmetadata_downloads_url, notice: 'Bulk descmetadata download was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bulk_descmetadata_download
      @bulk_descmetadata_download = BulkDescmetadataDownload.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def bulk_descmetadata_download_params
      params.require(:bulk_descmetadata_download).permit(:filename)
    end
end
