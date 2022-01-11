# frozen_string_literal: true

# Overrides for Blacklight helpers
module ArgoHelper
  include BlacklightHelper
  include ValueHelper

  # This overrides a blacklight helper so that the page is full-width
  def container_classes
    return super if controller_name == 'apo'

    action_name == 'show' && controller_name == 'catalog' ? 'container' : 'container-fluid'
  end

  def render_thumbnail_helper(doc, thumb_class = '', thumb_alt = '', thumb_style = 'max-width:240px;max-height:240px;')
    image_tag doc.thumbnail_url, class: thumb_class, alt: thumb_alt, style: thumb_style if doc.thumbnail_url
  end

  def render_datastream_link(document)
    return unless document.admin_policy?

    link_to 'MODS bulk loads', apo_bulk_jobs_path(document), id: 'bulk-button', class: 'button btn btn-primary'
  end
end
