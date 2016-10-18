require 'spec_helper'

class TestClass
  include Argo::ProfileQueries
end

describe Argo::ProfileQueries do
  subject { TestClass.new }
  # let(:blacklight_params) { { controller: 'profile' } }
  before do
    allow(subject).to receive(:blacklight_params).and_return(blacklight_params)
  end
  context 'in ProfileController' do
    let(:blacklight_params) { { 'controller' => 'profile' } }
    it 'adds in required facet fields' do
      catalog_config = CatalogController.blacklight_config.deep_copy
      solr_parameters = subject.add_profile_queries(catalog_config)
      facet_fields = solr_parameters.facet_fields.map{ |f| f[0] } + solr_parameters['facet.field']
      required_fields = [
        SolrDocument::FIELD_APO_TITLE.to_s,
        SolrDocument::SolrDocument::FIELD_COLLECTION_TITLE.to_s,
        'rights_descriptions_ssim',
        'content_type_ssim',
        'use_statement_ssim',
        'copyright_ssim',
        'use_license_machine_ssi'
      ]
      expect(facet_fields).to include(*required_fields)
    end
    it 'adds in requred stats fields' do
      catalog_config = CatalogController.blacklight_config.deep_copy
      solr_parameters = subject.add_profile_queries(catalog_config)
      expect(solr_parameters['stats']).to be true
    end
  end
  context 'in another Controller' do
    let(:blacklight_params) { { 'controller' => 'catalog' } }
    it 'does not modify solr_params' do
      expect(subject.add_profile_queries(CatalogController.blacklight_config.deep_copy)).to eq CatalogController.blacklight_config.deep_copy
    end
  end
end
