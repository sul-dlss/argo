# frozen_string_literal: true

class ContentTypesController < ApplicationController
  before_action :load_and_authorize_resource

  def show
    @form = ContentTypeForm.new(@cocina_object)
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  # set the content type in the content metadata
  def update
    # if this object has been submitted and doesnt have an open version, they cannot change it.
    return unless enforce_versioning

    form = ContentTypeForm.new(@cocina)
    if form.validate(params)
      form.save
      redirect_to solr_document_path(params[:item_id]), notice: 'Content type updated!'
    else
      render_error('Invalid new content type.')
    end
  end

  private

  def render_error(msg)
    render status: :forbidden, plain: msg
  end

  def load_and_authorize_resource
    @cocina = Dor::Services::Client.object(params[:item_id]).find
    authorize! :manage_item, @cocina
  end
end
