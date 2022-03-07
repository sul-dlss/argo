# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit copyright' do
  let(:user) { create(:user) }
  let(:pid) { 'druid:dc243mg0841' }

  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
  let(:turbo_stream_headers) do
    { 'Accept' => "#{Mime[:turbo_stream]},#{Mime[:html]}",
      'Turbo-Frame' => 'edit_copyright' }
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    sign_in user, groups: ['sdr:administrator-role']
  end

  describe 'display the form' do
    context 'with an item' do
      let(:cocina_model) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::Vocab.object,
                               'externalIdentifier' => pid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                               },
                               'access' => {},
                               'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                               'structural' => {},
                               'identification' => {}
                             })
      end

      it 'draws the form' do
        get "/items/#{pid}/edit_copyright", headers: turbo_stream_headers

        expect(response).to be_successful
      end
    end

    context 'with a collection that has identification' do
      let(:cocina_model) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::Vocab.collection,
                               'externalIdentifier' => pid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                               },
                               'access' => {},
                               'identification' => {
                                 'catalogLinks' => [
                                   {
                                     'catalog' => 'symphony',
                                     'catalogRecordId' => '10448742'
                                   }
                                 ]
                               },
                               'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' }
                             })
      end

      it 'draws the form' do
        get "/items/#{pid}/edit_copyright", headers: turbo_stream_headers
        expect(response).to be_successful
      end
    end
  end
end
