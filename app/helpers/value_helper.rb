module ValueHelper
  # Renderers
  def label_for_druid(druid)
    druid = druid.to_s.split(/\//).last # strip "info:fedora/"
    Rails.cache.fetch("label_for_#{druid}", expires_in: 1.hour) do
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

  def value_for_wf_error(args)
    _wf, step, message = args[:document].fetch(args[:field], ['::']).first.split(':', 3)
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
    link_to args[:document].apo_title, solr_document_path(args[:document].apo_pid)
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
        solr_document_path(val.gsub('info:fedora/', ''))
      )
    end.join('<br>').html_safe
  end

  def value_for_identifier_tesim(args)
    val = args[:document][args[:field]]
    Array(val).reject { |v| v == args[:document]['id'] }.sort.uniq.join(', ')
  end
end
