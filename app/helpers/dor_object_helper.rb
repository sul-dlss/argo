# frozen_string_literal: true

module DorObjectHelper
  # Metadata helpers
  def retrieve_terms(doc)
    terms = {
      creator: { selector: %w[sw_author_tesim] },
      title: { selector: %w[sw_display_title_tesim obj_label_tesim], combiner: ->(s) { s.join(' -- ') } },
      place: { selector: ['originInfo_place_placeTerm_tesim'] },
      publisher: { selector: %w[originInfo_publisher_tesim] },
      date: { selector: %w[originInfo_date_created_tesim] }
    }
    result = {}
    terms.each_pair do |term, finder|
      finder[:selector].each do |key|
        next unless doc[key].present?

        val = doc[key]
        com = finder[:combiner]
        result[term] = com ? com.call(val) : val.first
        break
      end
    end
    result
  end

  def render_citation(doc)
    terms = retrieve_terms(doc)
    result = ''
    result += "#{terms[:creator].html_safe} " if terms[:creator].present?
    result += "<em>#{terms[:title].html_safe}</em>" if terms[:title].present?
    origin_info = terms.values_at(:publisher, :place, :date).compact.join(', ')
    result += ": #{origin_info.html_safe}" if origin_info.present?
    result.html_safe
  end

  def render_workflows(doc)
    workflows = {}
    Array(doc[ActiveFedora::SolrService.solr_name('workflow_status', :symbol)]).each do |line|
      (wf, status, errors) = line.split(/\|/)
      workflows[wf] = { status: status, errors: errors.to_i }
    end
    render 'catalog/show_workflows', document_id: doc.id, workflows: workflows
  end
end
