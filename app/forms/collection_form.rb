# frozen_string_literal: true

# Inspired by Reform, but not exactly reform
# This is for the collection form and it's only used for create, not for update
# as it registers a new object on each call to `#save`
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
    @model = register_model if model.new_record?
    sync
    model.save
    Argo::Indexer.reindex_pid_remotely(model.pid)
  end

  # Copies the values to the model
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

  # @return [Hash] the parameters used to register an apo. Must be called after `validate`
  def cocina_model
    reg_params = {
      label: params[:collection_title].presence || ':auto',
      version: 1,
      type: Cocina::Models::Vocab.collection,
      access: {},
      administrative: {
        hasAdminPolicy: params[:apo_pid]
      }
    }

    raw_rights = params[:collection_catkey].present? ? params[:collection_rights_catkey] : params[:collection_rights]
    reg_params[:access] = access(raw_rights)

    if params[:collection_catkey].present?
      reg_params[:identification] = {
        catalogLinks: [{ catalog: 'symphony', catalogRecordId: params[:collection_catkey] }]
      }
    end

    Cocina::Models::RequestCollection.new(reg_params)
  end

  # @param [String] the rights representation from the form
  # @return [Hash<Symbol,String>] a hash representing the Access subschema of the Cocina model
  def access(rights)
    if rights.start_with?('loc:')
      {
        access: 'location-based',
        readLocation: rights.delete_prefix('loc:')
      }
    else
      {
        access: rights
      }
    end
  end
end
