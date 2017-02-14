module RegistrationHelper

  # permission_keys will likely be a list of workgroups to which a user belongs plus
  # the user's sunetid, to determine which APOs grant the user registration permissions.
  def apo_list(permission_keys)
    return [] if permission_keys.blank?

    q = permission_keys.map { |key| %(apo_register_permissions_ssim:"#{key}") }.join(' OR ')

    result = Dor::SearchService.query(
      q,
      :defType => 'lucene',
      :rows => 99999,
      :fl => 'id,tag_ssim,sw_display_title_tesim',
      :fq => ['objectType_ssim:adminPolicy', '!tag_ssim:"Project : Hydrus"']
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
      'Manuscript (ltr)',
      'Manuscript (rtl)',
      'Map',
      'Media',
      'Software',
      '3D'
    ]
  end

  # the names of the workflows defined in the external system (e.g Goobi)
  # the selected one will create a tag in the object with the value to be passed (to goobi), the tag prefix is defined in constants.rb
  def external_workflow_names
    %w(Test_Workflow Test_Workflow_QA Test_Workflow_OCR Test_Workflow_OCR_METS)
  end

  def metadata_sources
    [
      %w(Auto auto)
    ]
  end
end
