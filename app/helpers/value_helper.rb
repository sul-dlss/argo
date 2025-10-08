# frozen_string_literal: true

module ValueHelper
  # TODO: dynamically generate these methods so we don't hardcode Solr field identifiers

  def value_for_wf_error(args)
    _wf, step, message = args[:document].fetch(args[:field], ['::']).first.split(':', 3)
    "#{step} : #{message}"
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
    link_to args[:document].apo_title, solr_document_path(args[:document].apo_druid)
  end

  # Links to an admin policy for a given document and objects that have that policy. This can be abstracted away
  # from using `apo_title` when Argo updates to a version of Blacklight which
  # allows us to send config parameters along. This has already been implemented
  # in https://github.com/projectblacklight/blacklight/commit/c0e3b2232cfd3247e158a4f0297ffd8bbf1c524f
  # @param [Hash] args
  # @see Blacklight::DocumentPresenter#get_field_values
  # @return [String]
  def link_to_admin_policy_with_objs(args)
    policy_link = link_to_admin_policy(args)
    facet_config = facet_configuration_for_field(SolrDocument::FIELD_APO_ID)
    path_for_facet = facet_item_presenter(facet_config, args[:document].apo_druid,
                                          SolrDocument::FIELD_APO_ID).href
    objs_link = link_to 'All objects with this APO', path_for_facet
    "#{policy_link} (#{objs_link})".html_safe
  end

  ##
  # Could be combined with #link_to_admin_policy when config parameters version
  # of Blacklight is updated.
  # @see #link_to_admin_policy
  # @return [String]
  def links_to_collections(**args)
    args[:with_objs] = false
    links_to_collections_with_objs(**args)
  end

  ##
  # Could be combined with #link_to_admin_policy when config parameters version
  # of Blacklight is updated.
  # @see #link_to_admin_policy
  # @return [String]
  def links_to_collections_with_objs(**args)
    with_objs = args.fetch(:with_objs, true)
    facet_config = facet_configuration_for_field(SolrDocument::FIELD_COLLECTION_ID)

    args[:value].map.with_index do |val, i|
      collection_link = link_to(
        args[:document].collection_titles[i],
        solr_document_path(val)
      )
      path_for_facet = facet_item_presenter(facet_config, val, SolrDocument::FIELD_COLLECTION_ID).href

      objs_link = link_to 'All objects in this collection', path_for_facet
      with_objs ? "#{collection_link} (#{objs_link})" : collection_link
    end.join('<br>').html_safe
  end

  def value_for_identifier_tesim(args)
    val = args[:document][args[:field]]
    Array(val).reject { |v| v == args[:document]['id'] }.sort.uniq.join(', ')
  end
end
