require 'spec_helper'

class TestClass
  include Argo::ProfileQueries
end

describe Argo::ProfileQueries do
  subject { TestClass.new }
  let(:blacklight_params) { { controller: 'profile' } }
  before do
    allow(subject).to receive(:blacklight_params).and_return(blacklight_params)
  end
  context 'in ProfileController' do
    let(:blacklight_params) { { 'controller' => 'profile' } }
    it 'adds in required facet fields' do
      catalog_config = CatalogController.blacklight_config.deep_copy
      solr_parameters = subject.add_profile_queries(catalog_config)
      facet_fields = solr_parameters.facet_fields.map { |f| f[0] } + solr_parameters['facet.field']
      required_fields = [
        SolrDocument::FIELD_APO_TITLE.to_s,
        SolrDocument::FIELD_COLLECTION_TITLE.to_s,
        'rights_descriptions_ssim',
        'content_type_ssim',
        'use_statement_ssim',
        'copyright_ssim',
        'use_license_machine_ssi',
        'sw_format_ssim',
        'sw_language_ssim',
        'topic_ssim',
        'sw_subject_geographic_ssim',
        'sw_subject_temporal_ssim',
        'sw_genre_ssim'
      ]
      expect(facet_fields).to include(*required_fields)
    end
    it 'adds in requred stats fields' do
      catalog_config = CatalogController.blacklight_config.deep_copy
      solr_parameters = subject.add_profile_queries(catalog_config)
      stats_fields = solr_parameters['stats.field']
      required_fields = %w(
        sw_pub_date_facet_ssi
        content_file_count_itsi
        shelved_content_file_count_itsi
        preserved_size_dbtsi
        catkey_id_ssim
      )
      expect(solr_parameters['stats']).to be true
      expect(stats_fields).to include(*required_fields)
    end
    it 'adds in required pivot fields' do
      catalog_config = CatalogController.blacklight_config.deep_copy
      solr_parameters = subject.add_profile_queries(catalog_config)
      pivot_fields = solr_parameters['facet.pivot']
      required_fields = ["#{SolrDocument::FIELD_OBJECT_TYPE},processing_status_text_ssi"]
      expect(pivot_fields).to include(*required_fields)
    end
    it 'adds in required facet queries' do
      catalog_config = CatalogController.blacklight_config.deep_copy
      solr_parameters = subject.add_profile_queries(catalog_config)
      facet_query = solr_parameters['facet.query']
      required_fields = ['-rights_primary_ssi:"dark" AND published_dttsim:*']
      expect(facet_query).to include(*required_fields)
    end
  end
  context 'in another Controller' do
    let(:blacklight_params) { { 'controller' => 'catalog' } }
    it 'does not modify solr_params' do
      catalog_config = CatalogController.blacklight_config.deep_copy
      solr_parameters = subject.add_profile_queries(catalog_config)
      expect(solr_parameters['facet.field']).to eq catalog_config['facet.field']
    end
  end
end
