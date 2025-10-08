# frozen_string_literal: true

require 'rails_helper'

class TestClass
  include Argo::AccessControlsEnforcement
end

RSpec.describe Argo::AccessControlsEnforcement, type: :model do
  let(:user) do
    instance_double(User,
                    admin?: false,
                    manager?: false,
                    viewer?: false,
                    permitted_apos: [])
  end

  let(:scope) { instance_double(Blacklight::SearchService, context: { current_user: user }) }

  before do
    @obj = TestClass.new
    expect(@obj).to receive(:scope).at_least(:once).and_return(scope)
  end

  describe 'add_access_controls_to_solr_params' do
    it 'adds a fq that requires the apo' do
      allow(user).to receive(:permitted_apos).and_return(['druid:cb081vd1895'])
      solr_params = {}
      @obj.add_access_controls_to_solr_params(solr_params)
      expect(solr_params).to eq(fq: ["#{SolrDocument::FIELD_APO_ID}:(\"druid:cb081vd1895\")"])
    end

    it 'adds to an existing fq' do
      allow(user).to receive(:permitted_apos).and_return(['druid:cb081vd1895'])
      solr_params = { fq: ["#{SolrDocument::FIELD_APO_ID}:(druid\\:ab123cd4567)"] }
      @obj.add_access_controls_to_solr_params(solr_params)
      expect(solr_params).to eq(fq: ["#{SolrDocument::FIELD_APO_ID}:(druid\\:ab123cd4567)",
                                     "#{SolrDocument::FIELD_APO_ID}:(\"druid:cb081vd1895\")"])
    end

    it 'builds a valid query if there arent any apos' do
      solr_params = {}
      @obj.add_access_controls_to_solr_params(solr_params)
      expect(solr_params).to eq(fq: ["#{SolrDocument::FIELD_APO_ID}:(dummy_value)"])
    end

    it 'returns no fq if the user is a repository admin' do
      allow(user).to receive(:admin?).and_return(true)
      solr_params = {}
      @obj.add_access_controls_to_solr_params(solr_params)
      expect(solr_params).to eq({})
    end

    it 'returns no fq if the user is a repository viewer' do
      allow(user).to receive(:viewer?).and_return(true)
      solr_params = {}
      @obj.add_access_controls_to_solr_params(solr_params)
      expect(solr_params).to eq({})
    end
  end
end
