# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Registration', type: :request do
  let(:bare_druid) { 'bc123df4567' }
  let(:cocina_admin_policy) do
    instance_double(Cocina::Models::AdminPolicy,
                    externalIdentifier: druid,
                    administrative: cocina_admin_policy_administrative)
  end
  let(:cocina_admin_policy_administrative) do
    instance_double(Cocina::Models::AdminPolicyAdministrative,
                    accessTemplate: default_access,
                    collectionsForRegistration: collections)
  end
  let(:collections) { [] }
  let(:druid) { "druid:#{bare_druid}" }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_admin_policy) }
  let(:user) { create(:user) }
  let(:headers) { { 'ACCEPT' => 'application/json' } }

  before do
    sign_in user
    allow(user).to receive(:admin?).and_return(true)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  describe 'rights_list' do
    context 'when Stanford is the read group and discover is world' do
      let(:default_access) do
        Cocina::Models::AdminPolicyAccessTemplate.new(view: 'stanford')
      end

      it 'shows Stanford as the default' do
        get "/registration/rights_list?apo_id=#{bare_druid}", headers: headers
        expect(response.body.include?('Stanford (APO default)')).to be(true)
      end
    end

    context 'when the read group is not Stanford' do
      let(:default_access) do
        Cocina::Models::AdminPolicyAccessTemplate.new
      end

      it 'does not show Stanford as the default' do
        get "/registration/rights_list?apo_id=#{bare_druid}", headers: headers
        expect(response.body.include?('Stanford (APO default)')).to be(false)
      end
    end

    context 'when discover and read are both world' do
      let(:default_access) do
        Cocina::Models::AdminPolicyAccessTemplate.new(view: 'world')
      end

      it 'shows World as the default' do
        get "/registration/rights_list?apo_id=#{bare_druid}", headers: headers

        expect(response.body.include?('World (APO default)')).to be(true)
      end
    end

    context 'when discover and read are both none' do
      let(:default_access) do
        Cocina::Models::AdminPolicyAccessTemplate.new(view: 'dark')
      end

      it 'shows Dark as the default' do
        get "/registration/rights_list?apo_id=#{bare_druid}", headers: headers

        expect(response.body.include?('Dark (Preserve Only) (APO default)')).to be(true)
      end
    end

    context 'when discover is world and read is none' do
      let(:default_access) do
        Cocina::Models::AdminPolicyAccessTemplate.new(view: 'citation-only')
      end

      it 'shows Citation Only as the default' do
        get "/registration/rights_list?apo_id=#{bare_druid}", headers: headers

        expect(response.body.include?('Citation Only (APO default)')).to be(true)
      end
    end

    context 'when there is no default_access' do
      let(:default_access) do
        nil
      end

      it 'shows no default' do
        get "/registration/rights_list?apo_id=#{bare_druid}", headers: headers

        expect(response.body.include?('World (APO default)')).to be(false)
        expect(response.body.include?('Stanford (APO default)')).to be(false)
        expect(response.body.include?('Citation Only (APO default)')).to be(false)
        expect(response.body.include?('Dark (Preserve Only) (APO default)')).to be(false)
      end
    end
  end

  describe 'tracksheet' do
    before do
      allow(TrackSheet).to receive(:new).with([bare_druid]).and_return(track_sheet)
    end

    let(:default_access) { '' }
    let(:bare_druid) { 'xb482ww9999' }
    let(:track_sheet) { instance_double(TrackSheet, generate_tracking_pdf: doc) }
    let(:doc) { instance_double(Prawn::Document, render: '') }

    it 'generates a tracking sheet with the right default name' do
      get "/registration/tracksheet?druid=#{bare_druid}", headers: headers

      expect(response.headers['Content-Type']).to eq('pdf; charset=utf-8')
      expect(response.headers['content-disposition']).to eq('attachment; filename=tracksheet-1.pdf')
    end

    it 'generates a tracking sheet with the specified name (and sequence number)' do
      test_name = 'test_name'
      test_seq_no = 7
      get "/registration/tracksheet?druid=#{bare_druid}&name=#{test_name}&sequence=#{test_seq_no}", headers: headers

      expect(response.headers['content-disposition']).to eq("attachment; filename=#{test_name}-#{test_seq_no}.pdf")
    end
  end

  describe '#collection_list' do
    let(:default_access) { '' }

    it 'handles invalid parameters' do
      expect { get '/registration/collection_list', headers: headers }.to raise_error(ActionController::ParameterMissing)
    end

    context 'when there are no collections' do
      let(:collections) { nil }

      it 'shows "None"' do
        get "/registration/collection_list?apo_id=#{druid}", headers: headers

        data = JSON.parse(response.body)
        expect(data).to include('' => 'None')
        expect(data.length).to eq(1)
      end
    end

    context 'when the collections are in solr' do
      let(:collections) { ['druid:pb873ty1662'] }
      let(:solr_response) do
        { 'response' => { 'docs' => [solr_doc] } }
      end
      let(:solr_doc) do
        {
          'sw_display_title_tesim' => [
            'Annual report of the State Corporation Commission showing the condition ' \
            'of the incorporated state banks and other institutions operating in ' \
            'Virginia at the close of business'
          ]
        }
      end

      before do
        allow(SearchService).to receive(:query).and_return(solr_response)
      end

      it 'alpha-sorts the collection list by title, except for the "None" entry, which should come first' do
        get "/registration/collection_list?apo_id=#{druid}", headers: headers

        data = JSON.parse(response.body)
        expect(data).to eq(
          '' => 'None',
          'druid:pb873ty1662' => 'Annual report of the State Corporation Commission showing... (pb873ty1662)'
        )
      end
    end
  end

  describe '#workflow_list' do
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
    let(:cocina_model) do
      Cocina::Models.build({
                             'label' => 'The APO',
                             'version' => 1,
                             'type' => Cocina::Models::ObjectType.admin_policy,
                             'externalIdentifier' => apo_id,
                             'administrative' => {
                               hasAdminPolicy: 'druid:hv992ry2431',
                               hasAgreement: 'druid:hp308wm0436',
                               registrationWorkflow: ['digitizationWF', 'dpgImageWF', Settings.apo.default_workflow_option, 'goobiWF'],
                               accessTemplate: { view: 'world', download: 'world' }
                             }
                           })
    end
    let(:apo_id) { 'druid:zt570tx3016' }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    it 'handles an APO with multiple workflows, putting the default workflow first always' do
      get "/registration/workflow_list?apo_id=#{apo_id}", headers: headers

      data = JSON.parse(response.body)
      expect(data).to eq [Settings.apo.default_workflow_option, 'digitizationWF', 'dpgImageWF', 'goobiWF']
    end
  end
end
