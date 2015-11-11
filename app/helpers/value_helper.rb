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

  def value_for_preserved_size_dbtsi(args)
    args[:document].get(args[:field]).to_i.bytestring('%.1f%s')
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

  def value_for_wf_error_ssim(args)
    _wf, step, message = args[:document].get(args[:field]).split(':', 3)
    step + ' : ' + message
  end

  def value_for_is_governed_by_ssim(args)
    target_id = args[:document].get('is_governed_by_ssim')
    target_name = ''
    links = ''
    target_id.split(',').each do |targ|
      target_name = args[:document].get('apo_title_ssim')
      links += link_to target_name, catalog_path(targ.split(/\//).last)
      links += '<br/>'
    end
    links.html_safe
  rescue StandardError => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    # value_for_related_druid('is_governed_by', args)
  end

  def value_for_is_member_of_collection_ssim(args)
    target_id = args[:document].get('is_member_of_collection_ssim')
    target_name = ''
    links = ''
    target_id.split(',').each do |targ|
      target_name = args[:document].get('collection_title_ssim')
      links += link_to target_name, catalog_path(targ.split(/\//).last)
      links += '<br/>'
    end
    links.html_safe
  rescue StandardError => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
  end

  def value_for_project_tag_ssim(args)
    val = args[:document].get(args[:field]).split(':').first
    link_to val, add_facet_params_and_redirect('project_tag_ssim', val)
  end

  def value_for_originInfo_date_created_tesim(args)
    val = Time.parse(args[:document][args[:field]].first)
    val.localtime.strftime '%Y.%m.%d %H:%M%p'
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
