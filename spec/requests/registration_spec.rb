# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Registration', type: :request do
  let(:druid) { 'druid:bc123df4567' }
  let(:bare_druid) { 'bc123df4567' }
  let(:user) { create(:user) }
  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  before do
    sign_in user
    allow(user).to receive(:admin?).and_return(true)
    allow(Repository).to receive(:find).and_return(cocina_admin_policy)
  end

  describe 'tracksheet' do
    before do
      allow(TrackSheet).to receive(:new).with([bare_druid]).and_return(track_sheet)
    end

    let(:cocina_admin_policy) do
      instance_double(Cocina::Models::AdminPolicyWithMetadata, externalIdentifier: druid)
    end
    let(:track_sheet) { instance_double(TrackSheet, generate_tracking_pdf: doc) }
    let(:doc) { instance_double(Prawn::Document, render: '') }

    it 'generates a tracking sheet with the right default name' do
      get "/registration/tracksheet?druid=#{druid}", headers: headers

      expect(response.headers['Content-Type']).to eq('pdf; charset=utf-8')
      expect(response.headers['content-disposition']).to eq('attachment; filename=tracksheet-1.pdf')
    end

    it 'generates a tracking sheet with the specified name (and sequence number)' do
      test_name = 'test_name'
      test_seq_no = 7
      get "/registration/tracksheet?druid=#{druid}&name=#{test_name}&sequence=#{test_seq_no}", headers: headers

      expect(response.headers['content-disposition']).to eq("attachment; filename=#{test_name}-#{test_seq_no}.pdf")
    end
  end

  describe 'the rights options' do
    let(:cocina_admin_policy) do
      build(:admin_policy_with_metadata, id: druid).new(
        administrative: {
          hasAdminPolicy: 'druid:hv992ry2431',
          hasAgreement: 'druid:hp308wm0436',
          registrationWorkflow: [Settings.apo.default_workflow_option]
        }
      )
    end

    context 'when there is no default_access' do
      it 'shows no default' do
        get "/apo/#{druid}/registration_options"

        expect(response.body.include?('World (APO default)')).to be(false)
        expect(response.body.include?('Stanford (APO default)')).to be(false)
        expect(response.body.include?('Citation Only (APO default)')).to be(false)
        expect(response.body.include?('Dark (Preserve Only) (APO default)')).to be(false)
      end
    end
  end

  describe 'the collection options' do
    let(:cocina_admin_policy) do
      build(:admin_policy_with_metadata, id: druid).new(
        administrative: {
          hasAdminPolicy: 'druid:hv992ry2431',
          hasAgreement: 'druid:hp308wm0436',
          registrationWorkflow: [Settings.apo.default_workflow_option],
          collectionsForRegistration: collections
        }
      )
    end

    context 'when there are no collections' do
      let(:collections) { [] }

      it 'shows "None"' do
        get "/apo/#{druid}/registration_options"
        options = rendered.find_css('#registration_collection option')
        expect(options.to_html).to include('None')
        expect(options.length).to eq(1)
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
        get "/apo/#{druid}/registration_options"
        options = rendered.find_css('#registration_collection option')
        expect(options.map { |node| [node.attr('value'), node.text] }).to eq [
          ['', 'None'],
          ['druid:pb873ty1662', 'Annual report of the State Corporation Commission showing... (pb873ty1662)']
        ]
      end
    end
  end

  describe 'the workflow list' do
    let(:cocina_admin_policy) do
      build(:admin_policy_with_metadata, id: druid).new(
        administrative: {
          hasAdminPolicy: 'druid:hv992ry2431',
          hasAgreement: 'druid:hp308wm0436',
          registrationWorkflow: ['digitizationWF', 'dpgImageWF', Settings.apo.default_workflow_option, 'goobiWF']
        }
      )
    end

    it 'handles an APO with multiple workflows, putting the default workflow first always' do
      get "/apo/#{druid}/registration_options"
      options = rendered.find_css('#registration_workflow_id option')

      expect(options.map(&:text)).to eq [Settings.apo.default_workflow_option, 'digitizationWF', 'dpgImageWF', 'goobiWF']
    end
  end
end
