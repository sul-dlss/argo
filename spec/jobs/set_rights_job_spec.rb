# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetRightsJob, type: :job do
  let(:pids) { ['druid:bb111cc2222', 'druid:cc111dd2233'] }
  let(:groups) { [] }

  let(:bulk_action) do
    create(
      :bulk_action,
      action_type: 'SetRightsJob'
    )
  end

  let(:user) { bulk_action.user }

  let(:cocina1) do
    Cocina::Models::DRO.new(
      {
        label: 'Stanford Item',
        version: 2,
        type: Cocina::Models::ObjectType.book,
        description: {
          title: [{ value: 'Stanford Item' }],
          purl: "https://purl.stanford.edu/#{pids[0]}"
        },
        externalIdentifier: pids[0],
        access: {
          view: 'stanford',
          download: 'stanford'
        },
        administrative: { hasAdminPolicy: 'druid:cg532dg5405' },
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
        },
        identification: {}
      }
    )
  end

  let(:cocina2) do
    Cocina::Models::DRO.new(
      {
        label: 'World Item',
        version: 3,
        type: Cocina::Models::ObjectType.image,
        description: {
          title: [{ value: 'World Item' }],
          purl: "https://purl.stanford.edu/#{pids[1]}"
        },
        externalIdentifier: pids[1],
        access: {
          view: 'world',
          download: 'world'
        },
        administrative: { 'hasAdminPolicy' => 'druid:cg532dg5405' },
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
        },
        identification: {}
      }
    )
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina2) }

  let(:state_service) { instance_double(StateService, allows_modification?: true) }
  let(:buffer) { StringIO.new }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(BulkJobLog).to receive(:open).and_yield(buffer)
    allow(subject.ability).to receive(:can?).and_return(true)
    allow(StateService).to receive(:new).and_return(state_service)
    allow(Dor::Services::Client).to receive(:object).with(pids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(pids[1]).and_return(object_client2)
    allow(object_client1).to receive(:update)
    allow(object_client2).to receive(:update)
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
  end

  context 'when updating one object' do
    let(:params) do
      {
        pids: [pids[0]],
        set_rights: {
          rights: 'world'
        }
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
      expect(buffer.string).to include "Successfully updated rights of #{pids[0]} (bulk_action.id=#{bulk_action.id})"
    end
  end

  context 'when updating two objects' do
    let(:params) do
      {
        pids: pids,
        set_rights: {
          rights: 'world'
        }
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

      expect(buffer.string).to include "Successfully updated rights of #{pids[0]} (bulk_action.id=#{bulk_action.id})"
      expect(buffer.string).to include "Successfully updated rights of #{pids[1]} (bulk_action.id=#{bulk_action.id})"
    end
  end
end
