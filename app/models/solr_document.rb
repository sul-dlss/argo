# -*- encoding : utf-8 -*-
class SolrDocument

  include Blacklight::Solr::Document
  include CatkeyConcern
  include DruidConcern

  # self.unique_key = 'id'

  # The following shows how to setup this blacklight document to display marc documents
  extension_parameters[:marc_source_field] = :marc_display
  extension_parameters[:marc_format_type ] = :marcxml
  use_extension(Blacklight::Solr::Document::Marc) do |document|
    document.key?(:marc_display)
  end

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Solr::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Solr::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Solr::Document::DublinCore)
  field_semantics.merge!(
    :title    => 'dc_title_ssi',
    :author   => 'dc_creator_ssi',
    :language => 'public_dc_language_tesim',
    :format   => 'public_dc_format_tesim'
  )

  def self.get_versions(doc)
    versions={}
    recs=doc['versions_ssm']
    if recs
      recs.each do |rec|
        (version, tag, desc)=rec.split(';')
        versions[version]={
          :tag  => tag,
          :desc => desc
        }
      end
    end
    versions
  end

  def self.get_milestones(doc)
    milestones={}
    Array(doc['lifecycle_ssim']).each do |m|
      (name, time) = m.split(/:/,2)
      next unless time  # skip basic values like: "registered"
      (time, version) = time.split(/;/,2)
      version = 1 unless version && version.length > 0
      milestones[version] ||= ActiveSupport::OrderedHash[
        'registered'  => {},  # each of these *could* have :display and :time elements
        'opened'      => {},
        'submitted'   => {},
        'described'   => {},
        'published'   => {},
        'deposited'   => {},
        'accessioned' => {},
        'indexed'     => {},
        'ingested'    => {}
      ]
      milestones[version].delete(version == '1' ? 'opened' : 'registered')  # only version 1 has 'registered'
      milestones[version][name] = {
        :time => DateTime.parse(time)
      }
    end
    return milestones
  end

end
