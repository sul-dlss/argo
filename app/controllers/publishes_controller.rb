# frozen_string_literal: true

# dispatches to the dor-services-app to (re/un)publish
class PublishesController < ApplicationController
  before_action :load_cocina

  def create
    authorize! :manage_item, @cocina

    Dor::Services::Client.object(@cocina.externalIdentifier).publish
    redirect_to solr_document_path(@cocina.externalIdentifier),
                notice: 'Object published! You still need to use the normal versioning ' \
                        'process to make sure your changes are preserved.'
  end

  def destroy
    authorize! :manage_item, @cocina

    Dor::Services::Client.object(@cocina.externalIdentifier).unpublish
    redirect_to solr_document_path(@cocina.externalIdentifier), notice: 'Object unpublished!'
  end

  private

  def load_cocina
    @cocina = Dor::Services::Client.object(params[:item_id]).find
  end
end
