# frozen_string_literal: true

# Overrides for Blacklight helpers
module ArgoHelper
  include BlacklightHelper
  include ValueHelper

  def render_thumbnail_helper(doc, thumb_class = '', thumb_alt = '', thumb_style = 'max-width:240px;max-height:240px;')
    image_tag doc.thumbnail_url, class: thumb_class, alt: thumb_alt, style: thumb_style if doc.thumbnail_url
  end

  def render_purl_link(document, link_text = 'PURL', opts = { target: '_blank' })
    link_to link_text, File.join(Settings.purl_url, document.druid), opts
  end

  def render_dor_link(document, link_text = 'Fedora UI', opts = { target: '_blank' })
    link_to link_text, File.join(Dor::Config.fedora.safeurl, "objects/#{document.id}"), opts
  end

  def render_index_info(document)
    "indexed by DOR Services v#{document.first('dor_services_version_ssi')}"
  end

  def render_searchworks_link(document, link_text = 'Searchworks', opts = { target: '_blank' })
    link_to link_text, "http://searchworks.stanford.edu/view/#{document.catkey}", opts
  end

  def render_datastream_link(document)
    return unless document.admin_policy?

    link_to 'MODS bulk loads', apo_bulk_jobs_path(document), id: 'bulk-button', class: 'button btn btn-primary'
  end
end
