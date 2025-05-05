# frozen_string_literal: true

# Handle editing the serials properties
class SerialsController < ApplicationController
  load_and_authorize_resource :cocina, parent: false, class: 'Repository', id_param: 'item_id'

  def edit
    @form = SerialsForm.new(@cocina)
  end

  def update
    @form = SerialsForm.new(@cocina)

    if @form.validate(params[:serials]) && @form.save
      Dor::Services::Client.object(@cocina.externalIdentifier).reindex

      redirect_to solr_document_path(@cocina.externalIdentifier), notice: 'Serials metadata has been updated!'
    else
      render turbo_stream: turbo_stream.replace('modal-frame', partial: 'edit'), status: :unprocessable_content
    end
  end
end
