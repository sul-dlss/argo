# frozen_string_literal: true

# dispatches to the dor-services-app to (re/un)publish
class PublishesController < ApplicationController
  before_action :load_cocina

  def create
    authorize! :update, @cocina

    Dor::Services::Client.object(@cocina.externalIdentifier).publish
    redirect_to solr_document_path(@cocina.externalIdentifier),
                notice: 'Object published! You still need to use the normal versioning ' \
                        'process to make sure your changes are preserved.'
  end

  def destroy
    authorize! :update, @cocina

    Dor::Services::Client.object(@cocina.externalIdentifier).unpublish
    redirect_to solr_document_path(@cocina.externalIdentifier), notice: 'Object unpublished!'
  end

  private

  def load_cocina
    @cocina = Repository.find(params[:item_id])
  end
end
