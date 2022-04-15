# frozen_string_literal: true

# This models the values set from the registration form
class RegistrationForm
  def initialize(params)
    @params = params
  end

  # @raise [Cocina::Models::ValidationError]
  def cocina_model
    catalog_links = []
    if params[:other_id] != 'label:'
      catalog, record_id = params[:other_id].split(':')
      catalog_links = [{ catalog:, catalogRecordId: record_id, refresh: false }]
    end

    model_params = {
      type: dro_type,
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
    case content_type_tag
    when 'Book (ltr)'
      structural[:hasMemberOrders] = [{ viewingDirection: 'left-to-right' }]
    when 'Book (rtl)'
      structural[:hasMemberOrders] = [{ viewingDirection: 'right-to-left' }]
    end
    model_params[:structural] = structural
    model_params[:administrative][:partOfProject] = params[:project] if params[:project].present?

    Cocina::Models::RequestDRO.new(model_params)
  end

  # All the tags from the form except the project and content type, which are handled specially
  def administrative_tags
    params[:tag].filter { |t| !t.start_with?('Process : Content Type') }
  end

  private

  attr_reader :params

  def dro_type
    case content_type_tag
    when 'Image'
      Cocina::Models::ObjectType.image
    when '3D'
      Cocina::Models::ObjectType.three_dimensional
    when 'Map'
      Cocina::Models::ObjectType.map
    when 'Media'
      Cocina::Models::ObjectType.media
    when 'Document'
      Cocina::Models::ObjectType.document
    when /^Manuscript/
      Cocina::Models::ObjectType.manuscript
    when 'Book (ltr)', 'Book (rtl)'
      Cocina::Models::ObjectType.book
    when 'Webarchive-seed'
      Cocina::Models::ObjectType.webarchive_seed
    when 'Geo'
      Cocina::Models::ObjectType.geo
    else
      Cocina::Models::ObjectType.object
    end
  end

  # helper method to get just the content type tag
  def content_type_tag
    content_tag = params[:tag].find { |tag| tag.start_with?('Process : Content Type') }
    content_tag.split(':').last.strip
  end
end
