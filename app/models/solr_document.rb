class SolrDocument
  include Blacklight::Solr::Document
  include ApoConcern
  include CatkeyConcern
  include CollectionConcern
  include DruidConcern
  include TitleConcern
  include DocumentDateConcern
  include PreservationSizeConcern
  include EmbargoConcern
  include ObjectTypeConcern

  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)
  field_semantics.merge!(
    title: FIELD_TITLE,
    author: 'dc_creator_ssi',
    language: 'sw_language_ssim',
    format: 'sw_format_ssim'
  )

  def get_versions
    versions = {}
    recs = self['versions_ssm']
    if recs
      recs.each do |rec|
        (version, tag, desc) = rec.split(';')
        versions[version] = {
          tag: tag,
          desc: desc
        }
      end
    end
    versions
  end

  def get_milestones
    milestones = {}
    Array(self['lifecycle_ssim']).each do |m|
      (name, time) = m.split(/:/, 2)
      next unless time # skip basic values like: "registered"
      (time, version) = time.split(/;/, 2)
      version = 1 unless version && version.length > 0
      milestones[version] ||= ActiveSupport::OrderedHash[
        'registered'  => {}, # each of these *could* have :display and :time elements
        'opened'      => {},
        'submitted'   => {},
        'described'   => {},
        'published'   => {},
        'deposited'   => {},
        'accessioned' => {},
        'indexed'     => {},
        'ingested'    => {}
      ]
      milestones[version].delete(version == '1' ? 'opened' : 'registered') # only version 1 has 'registered'
      milestones[version][name] = {
        time: DateTime.parse(time)
      }
    end
    milestones
  end
end
