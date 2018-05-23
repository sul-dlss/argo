# Manages HTTP interactions for creating collections
class CollectionsController < ApplicationController
  def new
    @apo = Dor.find params[:apo_id]
    authorize! :manage_item, @apo
  end

  def create
    @apo = Dor.find params[:apo_id]
    authorize! :manage_item, @apo

    form = CollectionForm.new
    return render 'new' unless form.validate(params.merge(apo_pid: params[:apo_id]))
    form.save
    collection_pid = form.model.id
    @apo.add_default_collection collection_pid
    redirect_to solr_document_path(params[:apo_id]), notice: "Created collection #{collection_pid}"
    @apo.save # indexing happens automatically
  end
end
