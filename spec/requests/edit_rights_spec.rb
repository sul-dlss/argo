# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Edit rights' do
  let(:user) { create(:user) }
  let(:druid) { 'druid:dc243mg0841' }

  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
  let(:turbo_stream_headers) do
    { 'Accept' => "#{Mime[:turbo_stream]},#{Mime[:html]}" }
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
                               'type' => Cocina::Models::ObjectType.object,
                               'externalIdentifier' => druid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                               },
                               'access' => {
                                 'view' => 'world',
                                 'download' => 'world'
                               },
                               'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                               'structural' => {},
                               'identification' => {}
                             })
      end

      it 'draws the form' do
        get "/items/#{druid}/edit_rights", headers: turbo_stream_headers

        expect(response).to be_successful
      end
    end

    context 'with a collection' do
      let(:cocina_model) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::ObjectType.collection,
                               'externalIdentifier' => druid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                               },
                               'access' => {
                                 'view' => 'world'
                               },
                               'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                               'identification' => {}
                             })
      end

      it 'draws the form' do
        get "/items/#{druid}/edit_rights", headers: turbo_stream_headers
        expect(response).to be_successful
      end
    end
  end

  describe 'display the show view (after cancel)' do
    context 'with an item' do
      let(:cocina_model) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::ObjectType.object,
                               'externalIdentifier' => druid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                               },
                               'access' => {},
                               'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                               'structural' => {},
                               'identification' => {}
                             })
      end

      it 'draws the component' do
        get "/items/#{druid}/show_rights", headers: turbo_stream_headers

        expect(response).to be_successful
      end
    end

    context 'with a collection' do
      let(:cocina_model) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::ObjectType.collection,
                               'externalIdentifier' => druid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                               },
                               'access' => {},
                               'identification' => {},
                               'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' }
                             })
      end

      it 'draws the component' do
        get "/items/#{druid}/show_rights", headers: turbo_stream_headers
        expect(response).to be_successful
      end
    end
  end
end
