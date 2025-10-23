# frozen_string_literal: true

# Draws the form for managing a release. The form kicks off a bulk action.
class ManageReleasesController < ApplicationController
  include Blacklight::Searchable

  load_and_authorize_resource :cocina, parent: false, class: 'Repository', id_param: 'item_id'

  def edit
    authorize! :update, @cocina
    _, @document = search_service.fetch params[:item_id]

    render layout: false
  end

  def update
    authorize! :update, @cocina

    Dor::Services::Client.object(@cocina.externalIdentifier).release_tags.create(tag: new_tag)

    redirect_to solr_document_path(@cocina.externalIdentifier), notice: "Updated release for #{@cocina.externalIdentifier}"
  end

  def new_tag
    Dor::Services::Client::ReleaseTag.new(
      to: params[:to],
      who: current_user.sunetid,
      what: 'self',
      release: params[:tag] == 'true',
      date: DateTime.now.utc.iso8601
    )
  end
end
