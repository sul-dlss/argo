module BlacklightSolrExtensions
  extend ActiveSupport::Concern
  include Blacklight::SearchHelper

  def add_params_to_current_search(new_params)
    p = session[:search] ? session[:search].dup : {}
    p[:f] = (p[:f] || {}).dup # the command above is not deep in rails3, !@#$!@#$

    new_params.each_pair do |field, value|
      p[:f][field] = (p[:f][field] || []).dup
      p[:f][field].push(value)
    end
    p
  end

  def add_params_to_current_search_and_redirect(params_to_add)
    new_params = add_params_to_current_search(params_to_add)

    # Delete page, if needed.
    new_params.delete(:page)

    # Delete any request params from facet-specific action, needed
    # to redir to index action properly.
    Blacklight::Solr::FacetPaginator.request_keys.values.each do |paginator_key|
      new_params.delete(paginator_key)
    end
    new_params.delete(:id)

    # Force action to be index.
    new_params[:action] = 'index'
    new_params
  end

  ##
  # Convert a facet/value pair into a solr fq parameter
  def facet_value_to_fq_string(facet_field, value)
    facet_config = blacklight_config.facet_fields[facet_field]
    case
      when (facet_config && facet_config.query)
        facet_config.query[value][:fq]
      when (value.is_a?(TrueClass) || value.is_a?(FalseClass) || value == 'true' || value == 'false')
        "#{facet_field}:#{value}"
      when (value.is_a?(Integer) || (value.to_i.to_s == value if value.respond_to? :to_i))
        "#{facet_field}:#{value}"
      when (value.is_a?(Float) || (value.to_f.to_s == value if value.respond_to? :to_f))
        "#{facet_field}:#{value}"
      when value.is_a?(Range)
        "#{facet_field}:[#{value.first} TO #{value.last}]"
      when facet_field =~ /.+_dt/
        "#{facet_field}:#{value}"
      else
        "{!raw f=#{facet_field}}#{value}"
    end
  end
end
