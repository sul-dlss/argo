# frozen_string_literal: true

# Inspired by Reform, but not exactly reform
# This is for the collection form and it's only used for create, not for update
# as it registers a new object (of type collection) on each call to `#save`
class CollectionForm
  extend ActiveModel::Naming
  extend ActiveModel::Translation

  def initialize
    @errors = ActiveModel::Errors.new(self)
  end

  # needed so that we can use ActiveModel::Errors
  def self.model_name
    Struct.new(:param_key, :route_key, :i18n_key, :human).new('collection_form', 'collection', 'collection', 'Collection')
  end

  # @param [HashWithIndifferentAccess] params the parameters from the form
  # @return [Boolean] true if the parameters are valid
  def validate(params)
    @params = params
    unless params[:collection_title].present? || params[:collection_catkey].present?
      @errors.add(:base, :title_or_catkey_blank,
                  message: 'missing collection_title or collection_catkey')
    end
    @errors.empty?
  end

  # Copies the values to the model and saves and indexes
  def save
    @model = register_model
  end

  attr_reader :errors, :model, :params

  delegate :to_key, :to_model, :new_record?, to: :model

  private

  # @return [Cocina::Models::Collection] registers the Collection
  def register_model
    Dor::Services::Client.objects.register(params: cocina_model).tap do |response|
      WorkflowClientFactory.build.create_workflow_by_name(response.externalIdentifier, 'accessionWF', version: '1')
    end
  end

  # @return [Hash] the parameters used to register a collection. Must be called after `validate`
  def cocina_model
    reg_params = {
      label: params[:collection_title].presence || ':auto',
      version: 1,
      type: Cocina::Models::Vocab.collection,
      administrative: {
        hasAdminPolicy: params[:apo_pid]
      }
    }

    reg_params[:description] = build_description if params[:collection_title].present? || params[:collection_abstract].present?

    raw_rights = params[:collection_catkey].present? ? params[:collection_rights_catkey] : params[:collection_rights]
    access = CocinaAccess.from_form_value(raw_rights)
    reg_params.merge!(access: access.value!) unless access.none?

    if params[:collection_catkey].present?
      reg_params[:identification] = {
        catalogLinks: [{ catalog: 'symphony', catalogRecordId: params[:collection_catkey] }]
      }
    end

    Cocina::Models::RequestCollection.new(reg_params)
  end

  def build_description
    { title: [{ value: params[:collection_title], status: 'primary' }] }.tap do |description|
      description[:note] = [{ value: params[:collection_abstract], type: 'summary' }] if params[:collection_abstract].present?
    end
  end
end
