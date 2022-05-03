# frozen_string_literal: true

# This models the values set from the registration form
class RegistrationForm
  attr_accessor :current_user

  def initialize(params)
    @params = params
  end

  def tags
    Array(params[:tags]).compact_blank + [registered_by_tag]
  end

  def registered_by_tag
    "Registered By : #{current_user.login}"
  end

  # @raise [Cocina::Models::ValidationError]
  def cocina_model
    catalog_links = []
    if params[:other_id] != 'label:'
      catalog, record_id = params[:other_id].split(':')
      catalog_links = [{ catalog:, catalogRecordId: record_id, refresh: false }]
    end

    model_params = {
      type: params[:content_type],
      label: params.require(:label),
      version: 1,
      administrative: {
        hasAdminPolicy: params.require(:admin_policy)
      },
      identification: {
        sourceId: params.require(:source_id),
        catalogLinks: catalog_links,
        barcode: params[:barcode_id]
      }.compact
    }

    access = CocinaDroAccess.from_form_value(params[:rights])
    model_params.merge!(access: access.value!) unless access.none?

    structural = {}
    structural[:isMemberOf] = [params[:collection]] if params[:collection].present?
    structural[:hasMemberOrders] = [{ viewingDirection: params[:viewing_direction] }] if params[:viewing_direction].present?

    model_params[:structural] = structural
    model_params[:administrative][:partOfProject] = params[:project] if params[:project].present?

    Cocina::Models::RequestDRO.new(model_params)
  end

  attr_reader :params
end
