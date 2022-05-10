# frozen_string_literal: true

class CatkeysController < ApplicationController
  load_and_authorize_resource :cocina, parent: false, class: 'Repository', id_param: 'item_id'

  ### classes that define a virtual catkey model object and data structure, used in form editing...persistence is in the cocina model
  class ModelProxy
    def initialize(id:, catkeys:)
      @id = id # the object ID
      @catkeys = catkeys # the array of catkey objects (defined in custom class below)
    end

    attr_reader :id, :catkeys

    def to_param
      @id
    end

    def persisted?
      true
    end
  end

  class CatkeyRow
    attr_accessor :value, :refresh, :id

    def initialize(attrs = {})
      @id = attrs[:value]
      @value = attrs[:value]
      @refresh = attrs[:refresh]
    end

    def persisted?
      id.present?
    end

    # from https://github.com/rails/rails/blob/f95c0b7e96eb36bc3efc0c5beffbb9e84ea664e4/activerecord/lib/active_record/nested_attributes.rb#L382-L384
    def _destroy; end
  end
  ###

  def edit
    @form = catkey_form
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def update
    return unless enforce_versioning

    @form = catkey_form
    respond_to do |format|
      if @form.validate(params[:catkey]) && @form.save
        Argo::Indexer.reindex_druid_remotely(@cocina.externalIdentifier)
        msg = "Catkeys for #{@cocina.externalIdentifier} have been updated!"
        format.html { redirect_to solr_document_path(@cocina.externalIdentifier, format: :html), notice: msg }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('modal-frame', partial: 'edit'), status: :unprocessable_entity
        end
      end
    end
  end

  private

  def catkey_form
    # fetch catkeys from object
    object_catkeys = @cocina.identification.catalogLinks.filter_map { |catalog_link| catalog_link if catalog_link.catalog == Constants::SYMPHONY }

    # if there are no object catkeys, provide an initial blank row, else form is initialized with catkeys in the object
    catkeys = if object_catkeys.size.zero?
                [CatkeyRow.new(value: '', refresh: true)]
              else
                object_catkeys.map { |catkey| CatkeyRow.new(value: catkey.catalogRecordId, refresh: catkey.refresh) }
              end
    CatkeyForm.new(
      ModelProxy.new(
        id: params[:item_id],
        catkeys:
      )
    )
  end
end
