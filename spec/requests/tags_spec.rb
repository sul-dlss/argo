# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tags' do
  let(:user) { create(:user) }

  before do
    sign_in user, groups: ['sdr:administrator-role']
  end

  describe '#search' do
    let(:client) { instance_double(Dor::Services::Client::AdministrativeTagSearch, search: '["foo : bar : baz"]') }

    before do
      allow(Dor::Services::Client).to receive(:administrative_tags).and_return(client)
    end

    it 'returns results' do
      get '/tags/search?q=foo'
      expect(response.body).to eq '["foo : bar : baz"]'
    end

    context 'when there is a failure' do
      before do
        allow(client).to receive(:search).and_raise(Dor::Services::Client::ConnectionFailed)
      end

      it 'returns results' do
        get '/tags/search?q=foo'
        expect(response.body).to eq '[]'
      end
    end
  end

  describe '#update' do
    let(:druid) { 'druid:bc123df4567' }
    let(:object_client) do
      instance_double(Dor::Services::Client::Object, find: cocina_model, administrative_tags: tags_client, reindex: true)
    end
    let(:cocina_model) { build(:dro_with_metadata) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    context 'when they have manage access' do
      let(:current_tag) { 'Some : Thing' }
      let(:tags_client) do
        instance_double(Dor::Services::Client::AdministrativeTags,
                        list: [current_tag],
                        update: true,
                        destroy: true,
                        create: true)
      end

      it 'updates tags' do
        patch "/items/#{druid}/tags", params: {
          tags: {
            tags_attributes: {
              '0' => { name: 'Some : Thing : Else', id: 'Some : Thing' }
            }
          }
        }
        expect(tags_client).to have_received(:update).with(current: current_tag, new: 'Some : Thing : Else')
        expect(object_client).to have_received(:reindex)
      end

      it 'deletes tag' do
        patch "/items/#{druid}/tags", params: {
          tags: {
            tags_attributes: {
              '0' => { name: 'Some : Thing : Else', id: 'Some : Thing', _destroy: '1' }
            }
          }
        }
        expect(tags_client).to have_received(:destroy).with(tag: current_tag)
        expect(object_client).to have_received(:reindex)
      end

      it 'adds a tag' do
        patch "/items/#{druid}/tags", params: {
          tags: {
            tags_attributes: {
              '0' => { name: 'New : Thing', id: '', _destroy: '' }
            }
          }
        }
        expect(object_client).to have_received(:reindex)
        expect(tags_client).to have_received(:create).with(tags: ['New : Thing'])
      end
    end
  end
end
