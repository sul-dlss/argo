# frozen_string_literal: true

# Overrides for Blacklight helpers

module ArgoHelper
  include BlacklightHelper
  include ValueHelper

  def structure_from_solr(solr_doc, prefix, suffix = 'display')
    prefixed_fields = Hash[solr_doc.to_h.select { |k, v| k =~ /^#{prefix}_\d+_.+_#{suffix}$/ }]
    result = Confstruct::HashWithStructAccess.new
    prefixed_fields.each_pair do |path_str, value|
      h = result
      path = path_str.sub(/_[^_]+$/, '').reverse.split(/_(?=\d+)/).collect(&:reverse).reverse.collect { |k| k.split(/_(?=\d+)/) }
      path.each do |step, index|
        if index.nil?
          h[step.to_sym] = value
        else
          h[step.to_sym] ||= []
          h = h[step.to_sym][index.to_i] ||= Confstruct::HashWithStructAccess.new
        end
      end
    end
    result
  end

  def get_thumbnail_info(doc)
    fname = doc['first_shelved_image_ss']
    return nil unless fname

    fname = File.basename(fname, File.extname(fname))
    druid = doc['id'].to_s.split(/:/).last
    url = "#{Settings.STACKS_URL}/iiif/#{druid}%2F#{ERB::Util.url_encode(fname)}/full/!400,400/0/default.jpg"
    { fname: fname, druid: druid, url: url }
  end

  def render_thumbnail_helper(doc, thumb_class = '', thumb_alt = '', thumb_style = 'max-width:240px;max-height:240px;')
    thumbnail_info = get_thumbnail_info(doc)
    return nil unless thumbnail_info

    thumbnail_url = thumbnail_info[:url]
    image_tag thumbnail_url, class: thumb_class, alt: thumb_alt, style: thumb_style
  end

  def render_purl_link(document, link_text = 'PURL', opts = { target: '_blank' })
    link_to link_text, File.join(Settings.PURL_URL, document.druid), opts
  end

  def render_dor_link(document, link_text = 'Fedora UI', opts = { target: '_blank' })
    link_to link_text, File.join(Dor::Config.fedora.safeurl, "objects/#{document.id}"), opts
  end

  def render_index_info(document)
    "indexed by DOR Services v#{document.first(Dor::IdentifiableIndexer::INDEX_VERSION_FIELD)}"
  end

  def render_searchworks_link(document, link_text = 'Searchworks', opts = { target: '_blank' })
    link_to link_text, "http://searchworks.stanford.edu/view/#{document.catkey}", opts
  end

  def render_datastream_link(document)
    return unless document.admin_policy?

    link_to 'MODS bulk loads', apo_bulk_jobs_path(document), id: 'bulk-button', class: 'button btn btn-primary'
  end
end
