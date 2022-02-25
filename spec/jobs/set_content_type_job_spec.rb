# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetContentTypeJob, type: :job do
  let(:pids) { ['druid:bb111cc2222', 'druid:cc111dd2233'] }
  let(:groups) { [] }
  let(:bulk_action) do
    create(
      :bulk_action,
      action_type: 'SetContentTypeJob'
    )
  end
  let(:params) do
    {
      pids: [pids[0]],
      set_content_type: {
        current_resource_type: 'image',
        new_content_type: 'book (ltr)',
        new_resource_type: 'page'
      }
    }
  end
  let(:user) { bulk_action.user }
  let(:cocina1) do
    Cocina::Models.build({
                           'label' => 'My Book Item',
                           'version' => 2,
                           'type' => Cocina::Models::Vocab.book,
                           'externalIdentifier' => pids[0],
                           'description' => {
                             title: [{ value: 'my dro' }],
                             purl: 'https://purl.stanford.edu/bc234fg5678'
                           },
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => { contains: [{ type: 'http://cocina.sul.stanford.edu/models/resources/page.jsonld',
                                                          label: 'Book page',
                                                          version: 1,
                                                          externalIdentifier: 'abc123456' },
                                                        { type: 'http://cocina.sul.stanford.edu/models/resources/image.jsonld',
                                                          label: 'Book page 2',
                                                          version: 1,
                                                          externalIdentifier: 'abc789012' }] },
                           'identification' => {}
                         })
  end
  let(:cocina2) do
    Cocina::Models.build({
                           'label' => 'My Map Item',
                           'version' => 3,
                           'type' => Cocina::Models::Vocab.image,
                           'externalIdentifier' => pids[1],
                           'description' => {
                             title: [{ value: 'my dro' }],
                             purl: 'https://purl.stanford.edu/bc234fg5678'
                           },
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => { contains: [{ type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                                                          label: 'Map label',
                                                          version: 1,
                                                          externalIdentifier: 'xyz012345' }] },
                           'identification' => {}
                         })
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina2) }

  let(:state_service) { instance_double(StateService, allows_modification?: true) }
  let(:buffer) { StringIO.new }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(subject).to receive(:with_bulk_action_log).and_yield(buffer)
    allow(subject.ability).to receive(:can?).and_return(true)
    allow(StateService).to receive(:new).and_return(state_service)
    allow(Dor::Services::Client).to receive(:object).with(pids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(pids[1]).and_return(object_client2)
    allow(object_client1).to receive(:update)
    allow(object_client2).to receive(:update)
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
  end

  context 'when book object with image and page resource types' do
    it 'changes the resource with image type to page type and logs success' do
      subject.perform(bulk_action.id, params)
      expect(object_client1).to have_received(:update)
        .with(
          params: a_cocina_object_with_types(
            resource_types: [Cocina::Models::Vocab::Resources.page, Cocina::Models::Vocab::Resources.image]
          )
        )
      expect(buffer.string).to include "Successfully updated content type of #{pids[0]} (bulk_action.id=#{bulk_action.id})"
    end
  end

  context 'when object resource types and content type are requested to change' do
    let(:params) do
      {
        pids: [pids[1]],
        set_content_type: {
          current_resource_type: 'file',
          new_content_type: 'map',
          new_resource_type: 'image'
        }
      }
    end

    it 'changes the content type to map and resource type' do
      subject.perform(bulk_action.id, params)
      expect(object_client2).to have_received(:update)
        .with(
          params: a_cocina_object_with_types(
            content_type: Cocina::Models::Vocab.map,
            resource_types: [Cocina::Models::Vocab::Resources.page, Cocina::Models::Vocab::Resources.image]
          )
        )
    end
  end

  context 'when new content type is book (rtl)' do
    let(:params) do
      {
        pids: [pids[0]],
        set_content_type: {
          current_resource_type: 'page',
          new_content_type: 'book (rtl)',
          new_resource_type: 'page'
        }
      }
    end

    it 'sets the viewing direction' do
      subject.perform(bulk_action.id, params)
      expect(object_client1).to have_received(:update)
        .with(
          params: a_cocina_object_with_types(
            content_type: Cocina::Models::Vocab.book,
            viewing_direction: 'right-to-left'
          )
        )
    end
  end

  context 'when a new resource type is provided but not a new content type' do
    let(:params) do
      {
        pids: [pids[0]],
        set_content_type: {
          current_resource_type: '',
          new_content_type: '',
          new_resource_type: 'page'
        }
      }
    end

    it 'logs an error' do
      subject.perform(bulk_action.id, params)
      expect(buffer.string).to include 'Must provide a new content type when changing resource type.'
      expect(object_client1).not_to have_received(:update)
    end
  end

  context 'when a no types are entered in the form' do
    let(:params) do
      {
        pids: [pids[0]],
        set_content_type: {
          current_resource_type: '',
          new_content_type: '',
          new_resource_type: ''
        }
      }
    end

    it 'logs an error' do
      subject.perform(bulk_action.id, params)
      expect(buffer.string).to include 'Must provide values for types.'
      expect(object_client1).not_to have_received(:update)
    end
  end

  context 'without structural metadata' do
    let(:structural) { {} }
    let(:params) do
      {
        pids: [pids[0]],
        set_content_type: {
          current_resource_type: '',
          new_content_type: 'map',
          new_resource_type: ''
        }
      }
    end

    it 'changes the content type only' do
      subject.perform(bulk_action.id, params)
      expect(object_client1).to have_received(:update)
        .with(params: a_cocina_object_with_types(content_type: Cocina::Models::Vocab.map))
    end
  end

  context 'when modification is not allowed' do
    let(:state_service) { instance_double(StateService, allows_modification?: false) }

    it 'does not update and logs an error' do
      subject.perform(bulk_action.id, params)
      expect(object_client2).not_to have_received(:update)
      expect(buffer.string).to include 'Object cannot be modified in its current state.'
    end
  end

  context 'when not authorized to manage object' do
    before do
      allow(subject.ability).to receive(:can?).and_return(false)
    end

    it 'does not update and logs "not authorized"' do
      subject.perform(bulk_action.id, params)
      expect(buffer.string).to include 'Not authorized'
      expect(object_client1).not_to have_received(:update)
    end
  end
end
