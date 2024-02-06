# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Registration' do
  let(:druid) { 'druid:bc123df4567' }
  let(:bare_druid) { 'bc123df4567' }
  let(:user) { create(:user) }
  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  let(:cocina_admin_policy) do
    instance_double(Cocina::Models::AdminPolicyWithMetadata, externalIdentifier: druid)
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
      get("/registration/tracksheet?druid=#{druid}", headers:)

      expect(response.headers['Content-Type']).to eq('pdf; charset=utf-8')
      expect(response.headers['content-disposition']).to eq('attachment; filename=tracksheet-1.pdf')
    end

    it 'generates a tracking sheet with the specified name (and sequence number)' do
      test_name = 'test_name'
      test_seq_no = 7
      get("/registration/tracksheet?druid=#{druid}&name=#{test_name}&sequence=#{test_seq_no}", headers:)

      expect(response.headers['content-disposition']).to eq("attachment; filename=#{test_name}-#{test_seq_no}.pdf")
    end
  end

  context 'when defaults are provided ("Back to form" button pressed)' do
    before do
      allow(AdminPolicyOptions).to receive(:for).and_return([[double]])
    end

    it 'sets the defaults on the form' do
      get '/registration?registration[content_type]=https%3A%2F%2Fcocina.sul.stanford.edu%2Fmodels%2Fmap&registration[project]=Nemo+maps' \
          '&registration[admin_policy]=druid%3Ahv992ry2431&registration[collection]=&registration[view_access]=stanford' \
          '&registration[download_access]=none&registration[controlled_digital_lending]=true&registration[workflow_id]=registrationWF'
      content_type_select = rendered.find_css('#registration_content_type option[selected]').first
      expect(content_type_select['value']).to eq 'https://cocina.sul.stanford.edu/models/map'
      project_input = rendered.find_css('#registration_project').first
      expect(project_input['value']).to eq 'Nemo maps'
      expect(rendered.find_css('#registration-options').first[:src]).to eq '/apo/druid:hv992ry2431/registration_options?collection=' \
                                                                           '&controlled_digital_lending=true&download_access=none' \
                                                                           '&view_access=stanford&workflow_id=registrationWF'
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
          'display_title_ss' => [
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

    context 'when access parameters are provided' do
      let(:collections) { [] }

      it 'uses the provided access parameters' do
        get "/apo/#{druid}/registration_options?view_access=stanford&download_access=location-based&access_location=spec" \
            '&controlled_digital_lending=false&workflow_id=wasSeedPreassemblyWF'
        selected_view_acccess = rendered.find_css('#registration_view_access option[@selected]').first
        expect(selected_view_acccess.text).to eq 'Stanford'
        expect(selected_view_acccess[:value]).to eq 'stanford'
        selected_download_acccess = rendered.find_css('#registration_download_access option[@selected]').first
        expect(selected_download_acccess.text).to eq 'Location based'
        expect(selected_download_acccess[:value]).to eq 'location-based'
        selected_access_location = rendered.find_css('#registration_access_location option[@selected]').first
        expect(selected_access_location.text).to eq 'spec'
        expect(selected_access_location[:value]).to eq 'spec'
        selected_worklow = rendered.find_css('#registration_workflow_id option[@selected]').first
        expect(selected_worklow.text).to eq 'wasSeedPreassemblyWF'
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

      expect(options.map(&:text)).to eq [Settings.apo.default_workflow_option, 'digitizationWF', 'dpgImageWF',
                                         'goobiWF']
    end
  end
end
