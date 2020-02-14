# frozen_string_literal: true

# Inspired by Reform, but not exactly reform, because of existing deficiencies
# in dor-services:
#  https://github.com/sul-dlss/dor-services/pull/360
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
    @model ||= register_model
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
    response = Dor::Services::Client.objects.register(params: register_params)
    WorkflowClientFactory.build.create_workflow_by_name(response[:pid], 'accessionWF', version: '1')
    # Once it's been created we populate it with its metadata
    Dor.find(response[:pid])
  end

  # @return [Hash] the parameters used to register an apo. Must be called after `validate`
  def register_params
    reg_params = {
      object_type: 'collection',
      admin_policy: params[:apo_pid]
    }
    reg_params[:label] = params[:collection_title].presence || ':auto'
    reg_params[:rights] = if reg_params[:label] == ':auto'
                            params[:collection_rights_catkey]
                          else
                            params[:collection_rights]
                          end
    reg_params[:rights] &&= reg_params[:rights].downcase
    col_catkey = params[:collection_catkey] || ''

    if col_catkey.present?
      reg_params[:seed_datastream] = ['descMetadata']
      reg_params[:metadata_source] = 'symphony'
      reg_params[:other_id] = "symphony:#{col_catkey}"
    else
      reg_params[:metadata_source] = 'label'
    end
    reg_params
  end
end
