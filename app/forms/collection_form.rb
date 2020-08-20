# frozen_string_literal: true

# Inspired by Reform, but not exactly reform
# This is for the collection form and it's only used for create, not for update
# as it registers a new object (of type collection) on each call to `#save`
class CollectionForm < BaseForm
  # @param [HashWithIndifferentAccess] params the parameters from the form
  # @return [Boolean] true if the parameters are valid
  def validate(params)
    @params = params
    @errors.push('missing collection_title or collection_catkey') unless params[:collection_title].present? || params[:collection_catkey].present?
    @errors.empty?
  end

  # Copies the values to the model and saves and indexes
  def save
    if model.new_record?
      @model = register_model
    else
      # update case
      # TODO: after cocina updater supports descriptive metadata, make a cocina update call instead
      sync
    end
    model.save
    # update index immediately. Do not pass Go. Do not collect $200.
    Argo::Indexer.reindex_pid_remotely(model.pid)
  end

  # Copies the abstract value to the model descMetadata
  def sync
    # NOTE: collection_abstract only appears in conjunction with collection_title
    #       and disjoint from collection_catkey
    return if params[:collection_abstract].blank?

    model.descMetadata.abstract = params[:collection_abstract]
  end

  private

  # @return [Dor::Collection] registers the Collection
  def register_model
    response = Dor::Services::Client.objects.register(params: cocina_model)
    WorkflowClientFactory.build.create_workflow_by_name(response.externalIdentifier, 'accessionWF', version: '1')
    # Once it's been created we populate it with its metadata
    Dor.find(response.externalIdentifier)
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

    reg_params[:description] = build_description if params[:collection_title].present? && params[:collection_abstract].present?

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
    {
      title: [{ value: params[:collection_title], status: 'primary' }],
      note: [{ value: params[:collection_abstract], type: 'summary' }]
    }
  end
end
