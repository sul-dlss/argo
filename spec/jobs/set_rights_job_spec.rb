# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetRightsJob do
  let(:druids) { ['druid:bb111cc2222', 'druid:cc111dd2233'] }
  let(:groups) { [] }

  let(:bulk_action) do
    create(
      :bulk_action,
      action_type: 'SetRightsJob'
    )
  end

  let(:user) { bulk_action.user }

  let(:cocina1) do
    build(:dro_with_metadata, id: druids[0]).new(
      access: {
        view: 'stanford',
        download: 'stanford'
      },
      structural: {
        contains: [
          {
            type: Cocina::Models::FileSetType.page,
            label: 'Book page',
            version: 1,
            externalIdentifier: 'abc123456',
            structural: {
              contains: [
                {
                  filename: 'p1.jpg',
                  externalIdentifier: 'abc123456',
                  label: 'p1.jpg',
                  type: Cocina::Models::ObjectType.file,
                  version: 1,
                  administrative: {
                    publish: true,
                    sdrPreserve: true,
                    shelve: true
                  },
                  hasMessageDigests: [],
                  access: {
                    view: 'stanford',
                    download: 'stanford'
                  }
                }
              ]
            }
          },
          {
            type: Cocina::Models::FileSetType.image,
            label: 'Book page 2',
            version: 1,
            externalIdentifier: 'abc789012',
            structural: {
              contains: [
                {
                  filename: 'p2.jpg',
                  externalIdentifier: 'abc123456',
                  label: 'p2.jpg',
                  type: Cocina::Models::ObjectType.file,
                  version: 1,
                  administrative: {
                    publish: true,
                    sdrPreserve: true,
                    shelve: true
                  },
                  hasMessageDigests: [],
                  access: {
                    view: 'stanford',
                    download: 'stanford'
                  }
                }
              ]
            }
          }
        ]
      }
    )
  end

  let(:cocina2) do
    build(:dro_with_metadata, id: druids[1]).new(
      access: {
        view: 'world',
        download: 'world'
      },
      structural: {
        contains: [
          {
            type: Cocina::Models::FileSetType.page,
            label: 'Book page',
            version: 1,
            externalIdentifier: 'abc123456',
            structural: {
              contains: [
                {
                  filename: 'p1.jpg',
                  externalIdentifier: 'abc123456',
                  label: 'p1.jpg',
                  type: Cocina::Models::ObjectType.file,
                  version: 1,
                  administrative: {
                    publish: true,
                    sdrPreserve: true,
                    shelve: true
                  },
                  hasMessageDigests: [],
                  access: {
                    view: 'stanford',
                    download: 'stanford'
                  }
                }
              ]
            }
          },
          {
            type: Cocina::Models::FileSetType.image,
            label: 'Book page 2',
            version: 1,
            externalIdentifier: 'abc789012',
            structural: {
              contains: [
                {
                  filename: 'p2.jpg',
                  externalIdentifier: 'abc789012',
                  label: 'p2.jpg',
                  type: Cocina::Models::ObjectType.file,
                  version: 1,
                  administrative: {
                    publish: true,
                    sdrPreserve: true,
                    shelve: true
                  },
                  hasMessageDigests: [],
                  access: {
                    view: 'stanford',
                    download: 'stanford'
                  }
                }
              ]
            }
          }
        ]
      }
    )
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina2) }

  let(:state_service) { instance_double(StateService, open?: true) }
  let(:buffer) { StringIO.new }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(BulkJobLog).to receive(:open).and_yield(buffer)
    allow(subject.ability).to receive(:can?).and_return(true)
    allow(StateService).to receive(:new).and_return(state_service)
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client2)
    allow(object_client1).to receive(:update)
    allow(object_client2).to receive(:update)
    allow(Argo::Indexer).to receive(:reindex_druid_remotely)
  end

  context 'when updating one object' do
    let(:params) do
      {
        druids: [druids[0]],
        view_access: 'world',
        download_access: 'world',
        controlled_digital_lending: '0'
      }
    end

    it 'changes access to world and logs success' do
      subject.perform(bulk_action.id, params)
      expect(object_client1).to have_received(:update)
        .with(
          params: cocina_object_with(
            access: {
              view: 'world',
              download: 'world'
            }
          )
        )
      expect(object_client2).not_to have_received(:update)
      expect(buffer.string).to include "Successfully updated rights for #{druids[0]}"
    end
  end

  context 'when updating two objects' do
    let(:params) do
      {
        druids:,
        view_access: 'world',
        download_access: 'world',
        controlled_digital_lending: '0'
      }
    end

    it 'changes access to world and logs success' do
      subject.perform(bulk_action.id, params)

      expect(object_client1).to have_received(:update)
        .with(
          params: cocina_object_with(
            access: {
              view: 'world',
              download: 'world'
            }
          )
        )

      expect(object_client2).to have_received(:update)
        .with(
          params: cocina_object_with(
            access: {
              view: 'world',
              download: 'world'
            }
          )
        )

      expect(buffer.string).to include "Successfully updated rights for #{druids[0]}"
      expect(buffer.string).to include "Successfully updated rights for #{druids[1]}"
    end
  end
end
