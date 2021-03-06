# frozen_string_literal: true

module ApoHelper
  # Retrieve a list of workflow templates from  the workflow service and return
  # an array suitable for select_tag options
  def workflow_options
    Rails.cache.fetch 'workflow-templates-select-options' do
      list = WorkflowClientFactory.build.workflow_templates
      list.map do |name|
        [name, name]
      end
    end
  end

  def agreement_options
    q = 'objectType_ssim:agreement'
    result = SearchService.query(q, rows: 99_999, fl: 'id,tag_ssim,sw_display_title_tesim')['response']['docs']
    result.sort! do |a, b|
      a['sw_display_title_tesim'].to_s <=> b['sw_display_title_tesim'].to_s
    end
    result.collect do |doc|
      [Array(doc['sw_display_title_tesim']).first.to_s, doc['id'].to_s]
    end
  end
end
