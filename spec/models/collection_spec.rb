# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Collection do
  let(:druid) { 'druid:dc243mg0841' }

  describe '#save' do
    subject(:collection) do
      described_class.new(cocina_model)
    end

    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
    let(:updated_model) do
      cocina_model.new(
        {
          'identification' => {
            'catalogLinks' => [{ catalog: 'symphony', catalogRecordId: '12345' }]
          }
        }
      )
    end
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
                             'identification' => {},
                             'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' }
                           })
    end

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    it 'updates the catkey' do
      collection.catkey = '12345'
      collection.save
      expect(object_client).to have_received(:update)
        .with(params: updated_model)
    end
  end
end
