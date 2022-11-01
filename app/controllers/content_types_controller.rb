# frozen_string_literal: true

class ContentTypesController < ApplicationController
  load_and_authorize_resource :cocina, parent: false, class: "Repository", id_param: "item_id"

  def edit
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
    if form.validate(params[:content_type])
      form.save
      redirect_to solr_document_path(params[:item_id]), notice: "Content type updated!"
    else
      render_error(form.errors.full_messages.to_sentence)
    end
  end

  private

  def render_error(msg)
    render status: :forbidden, plain: msg
  end
end
