# frozen_string_literal: true

module RegistrationHelper
  # permission_keys will likely be a list of workgroups to which a user belongs plus
  # the user's sunetid, to determine which APOs grant the user registration permissions.
  def apo_list(permission_keys)
    return [] if permission_keys.blank?

    q = permission_keys.map { |key| %(apo_register_permissions_ssim:"#{key}") }.join(' OR ')

    result = SearchService.query(
      q,
      defType: 'lucene',
      rows: 99_999,
      fl: 'id,tag_ssim,sw_display_title_tesim',
      fq: ['objectType_ssim:adminPolicy', '!tag_ssim:"Project : Hydrus"']
    )['response']['docs']

    result.sort! do |a, b|
      Array(a['tag_ssim']).include?('AdminPolicy : default') ? -1 : a['sw_display_title_tesim'].to_s <=> b['sw_display_title_tesim'].to_s
    end
    result.map do |doc|
      [Array(doc['sw_display_title_tesim']).first, doc['id'].to_s]
    end
  end

  def valid_content_types
    # the content types selectable in registration are capitalized but match what is available when setting content types
    #  in the bulk and item detail page for setting content types (exception: '3d' needs to go '3D')
    Constants::CONTENT_TYPES.keys.map { |content_type| content_type == '3d' ? '3D' : content_type.capitalize }
  end
end
