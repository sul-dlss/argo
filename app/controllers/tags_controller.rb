# frozen_string_literal: true

# This controller is responsible for managing tags on an item
class TagsController < ApplicationController
  def search
    render json: Dor::Services::Client.administrative_tags.search(q: params[:q])
  rescue Dor::Services::Client::ConnectionFailed
    render json: []
    raise
  end

  def update
    cocina = Dor::Services::Client.object(params[:item_id]).find
    authorize! :manage_item, cocina

    current_tags = tags_client.list

    @form = TagsForm.new(ModelProxy.new(id: params[:item_id], tags: current_tags.map { |name| Tag.new(name: name) }))
    @form.validate(params[:tags])
    @form.save

    reindex
    respond_to do |format|
      msg = "Tags for #{params[:item_id]} have been updated!"
      format.any { redirect_to solr_document_path(params[:item_id]), notice: msg }
    end
  end

  class ModelProxy
    def initialize(id:, tags:)
      @id = id
      @tags = tags
    end

    attr_reader :tags

    def to_param
      @id
    end

    def persisted?
      true
    end
  end

  class Tag
    attr_accessor :name, :id

    def initialize(attrs = {})
      self.name = attrs[:name]
      self.id = attrs[:name]
    end

    # from https://github.com/rails/rails/blob/f95c0b7e96eb36bc3efc0c5beffbb9e84ea664e4/activerecord/lib/active_record/nested_attributes.rb#L382-L384
    def _destroy; end

    def persisted?
      id.present?
    end
  end

  def edit
    tags = tags_client.list
    @form = TagsForm.new(
      ModelProxy.new(
        id: params[:item_id],
        tags: tags.map { |name| Tag.new(name: name, id: name) }
      )
    )

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  private

  def tags_client
    Dor::Services::Client.object(params[:item_id]).administrative_tags
  end

  def reindex
    Argo::Indexer.reindex_pid_remotely(params[:item_id])
  end
end
