# frozen_string_literal: true

module RegistrationHelper
  # permission_keys will likely be a list of workgroups to which a user belongs plus
  # the user's sunetid, to determine which APOs grant the user registration permissions.
  def apo_list(permission_keys)
    return [] if permission_keys.blank?

    q = permission_keys.map { |key| %(apo_register_permissions_ssim:"#{key}") }.join(' OR ')

    result = Dor::SearchService.query(
      q,
      defType: 'lucene',
      rows: 99999,
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

  def valid_object_types
    [
      %w(Item item),
      ['Workflow Definition', 'workflow']
    ]
  end

  def valid_content_types
    [
      'Book (ltr)',
      'Book (rtl)',
      'File',
      'Image',
      'Map',
      'Media',
      'Software',
      '3D',
      'Document'
    ]
  end

  def default_metadata_source
    [
      'Auto'
    ]
  end
end
