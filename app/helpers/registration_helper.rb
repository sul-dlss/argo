module RegistrationHelper

  def apo_list(*permission_keys)
    q = 'objectType_ssim:adminPolicy AND !tag_ssim:"Project : Hydrus"'
    unless permission_keys.empty?
      q += '(' + permission_keys.flatten.map { |key| %(apo_register_permissions_ssim:"#{key}") }.join(' OR ') + ')'
    end
    result = Dor::SearchService.query(q, :rows => 99999, :fl => 'id,tag_ssim,dc_title_tesim').docs
    result.sort! do |a, b|
      Array(a['tag_ssim']).include?('AdminPolicy : default') ? -1 : a['dc_title_tesim'].to_s <=> b['dc_title_tesim'].to_s
    end
    result.map do |doc|
      [Array(doc['dc_title_tesim']).first, doc['id'].to_s]
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
      'Book (flipbook, ltr)',
      'Book (flipbook, rtl)',
      'Book (image-only)',
      'File',
      'Image',
      'Manuscript (flipbook, ltr)',
      'Manuscript (flipbook, rtl)',
      'Manuscript (image-only)',
      'Map',
      'Media',
      'Software'
    ]
  end

  def metadata_sources
    [
      %w(Auto auto),
      %w(None none)
    ]
  end
end
