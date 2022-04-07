# frozen_string_literal: true

# This controller is responsible for managing tags on an item
class TagsController < ApplicationController
  def search
    render json: Dor::Services::Client.administrative_tags.search(q: params[:q])
  rescue Dor::Services::Client::ConnectionFailed
    Honeybadger.notify('connection to DSA to search for tags failed', q: params[:q])
    render json: []
  end

  def update
    cocina = Repository.find(params[:item_id])
    authorize! :manage_item, cocina

    current_tags = tags_client.list

    @form = TagsForm.new(ModelProxy.new(id: params[:item_id], tags: current_tags.map { |name| Tag.new(name: name) }))
    respond_to do |format|
      if @form.validate(params[:tags]) && @form.save
        reindex
        msg = "Tags for #{params[:item_id]} have been updated!"
        format.html { redirect_to solr_document_path(params[:item_id], format: :html), notice: msg }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('modal-frame', partial: 'edit'), status: :unprocessable_entity
        end
      end
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
  end

  private

  def tags_client
    Dor::Services::Client.object(params[:item_id]).administrative_tags
  end

  def reindex
    Argo::Indexer.reindex_druid_remotely(params[:item_id])
  end
end
