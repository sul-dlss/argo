module ValueHelper

  # Renderers
  def label_for_druid(druid)
    druid = druid.to_s.split(/\//).last # strip "info:fedora/"
    Rails.cache.fetch("label_for_#{druid}", :expires_in => 1.hour) do
      item = @apo if @apo && druid == @apo.pid
      item = @obj if @obj && druid == @obj.pid
      begin
        item ||= Dor.find(druid)
        item.label
      rescue
        druid
      end
    end
  end

  # TODO: dynamically generate these methods so we don't hardcode Solr field identifiers

  ##
  # @return [String]
  def preserved_size_human(args)
    number_to_human_size(args[:document].preservation_size)
  end

  def value_for_related_druid(predicate, args)
    target_id = args[:document].get("#{predicate}_ssim")
    target_name = ''
    links = ''
    target_id.split(',').each do |targ|
      target_name = label_for_druid(targ)
      links += link_to target_name, catalog_path(targ.split(/\//).last)
      links += '<br/>'
    end
    links.html_safe
  rescue StandardError => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
  end

  def value_for_wf_error(args)
    _wf, step, message = args[:document].get(args[:field]).split(':', 3)
    step + ' : ' + message
  end

  ##
  # Links to an admin policy for a given document. This can be abstracted away
  # from using `apo_title` when Argo updates to a version of Blacklight which
  # allows us to send config parameters along. This has already been implemented
  # in https://github.com/projectblacklight/blacklight/commit/c0e3b2232cfd3247e158a4f0297ffd8bbf1c524f
  # @param [Hash] args
  # @see Blacklight::DocumentPresenter#get_field_values
  # @return [String]
  def link_to_admin_policy(args)
    link_to args[:document].apo_title, catalog_path(args[:document].apo_pid)
  end

  ##
  # Could be combined with #link_to_admin_policy when config parameters version
  # of Blacklight is updated.
  # @see #link_to_admin_policy
  # @return [String]
  def links_to_collections(args)
    args[:value].map.with_index do |val, i|
      link_to(
        args[:document].collection_titles[i],
        catalog_path(val.gsub('info:fedora/', ''))
      )
    end.join('<br>').html_safe
  end

  # @return [String]
  def value_for_date_as_localtime(args)
    date_value = args[:document][args[:field]].first
    # Try to return the date in local time zone;
    # assume it can be parsed according to app time zone.
    return '' if date_value.nil?
    val = Time.zone.parse(date_value)
    return date_value.to_s if val.nil?
    val.localtime.strftime '%Y.%m.%d %H:%M%p'
  rescue ArgumentError
    date_value.to_s
  end

  def value_for_identifier_tesim(args)
    val = args[:document][args[:field]]
    Array(val).reject { |v| v == args[:document]['id'] }.sort.uniq.join(', ')
  end

  def value_for_tag_ssim(args)
    val = args[:document][args[:field]]
    tags = Array(val).uniq.collect do |v|
      link_to v, add_facet_params_and_redirect('tag_ssim', v)
    end
    tags.join('<br/>').html_safe
  end

  # not actually called yet, requires Blacklight 4.2.0
  def facet_model_helper(value)
    value.gsub(/^info:fedora\/(afmodel:)?/, '')
  end
end
