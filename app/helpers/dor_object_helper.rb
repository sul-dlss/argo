# frozen_string_literal: true

module DorObjectHelper
  # Metadata helpers
  def retrieve_terms(doc)
    terms = {
      creator: { selector: %w(sw_author_tesim) },
      title: { selector: %w(sw_display_title_tesim obj_label_tesim), combiner: lambda { |s| s.join(' -- ') } },
      place: { selector: ['originInfo_place_placeTerm_tesim'] },
      publisher: { selector: %w(originInfo_publisher_tesim) },
      date: { selector: %w(originInfo_date_created_tesim) }
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

  def render_datetime(datetime)
    return '' if datetime.nil? || datetime == ''

    # this needs to use the timezone set in config.time_zone
    begin
      zone = ActiveSupport::TimeZone.new('Pacific Time (US & Canada)')
      d = datetime.is_a?(Time) ? datetime : DateTime.parse(datetime).in_time_zone(zone)
      I18n.l(d)
    rescue
      d = datetime.is_a?(Time) ? datetime : Time.parse(datetime.to_s)
      d.strftime('%Y-%m-%d %I:%M%p')
    end
  end

  def render_qfacet_value(facet_solr_field, item, options = {})
    params = add_facet_params(facet_solr_field, item.qvalue)
    Rails.cache.fetch('route_for' + params.to_s, expires_in: 1.hour) do
      (link_to_unless(options[:suppress_link], item.value, params, class: 'facet_select') + ' ' + render_facet_count(item.hits)).html_safe
    end
  end

  def render_workflows(doc)
    workflows = {}
    Array(doc[ActiveFedora::SolrService.solr_name('workflow_status', :symbol)]).each do |line|
      (wf, status, errors) = line.split(/\|/)
      workflows[wf] = { status: status, errors: errors.to_i }
    end
    render 'catalog/show_workflows', document_id: doc.id, workflows: workflows
  end

  # rubocop:disable Layout/LineLength
  def render_ds_profile_header(ds)
    dscd = ds.createDate
    dscd = dscd.xmlschema if dscd.is_a?(Time)
    %(<foxml:datastream ID="#{ds.dsid}" STATE="#{ds.state}" CONTROL_GROUP="#{ds.controlGroup}" VERSIONABLE="#{ds.versionable}">\n  <foxml:datastreamVersion ID="#{ds.dsVersionID}" LABEL="#{ds.label}" CREATED="#{dscd}" MIMETYPE="#{ds.mimeType}">)
  end
  # rubocop:enable Layout/LineLength
end
