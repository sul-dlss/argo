# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetContentTypeJob, type: :job do
  let(:druids) { ['druid:bb111cc2222', 'druid:cc111dd2233', 'druid:ff123gg4567'] }
  let(:groups) { [] }
  let(:bulk_action) do
    create(
      :bulk_action,
      action_type: 'SetContentTypeJob'
    )
  end
  let(:params) do
    {
      druids: [druids[0]],
      current_resource_type: 'https://cocina.sul.stanford.edu/models/resources/image',
      new_content_type: 'https://cocina.sul.stanford.edu/models/book',
      viewing_direction: 'left-to-right',
      new_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page'
    }
  end
  let(:user) { bulk_action.user }
  let(:cocina1) do
    build(:dro, id: druids[0], type: Cocina::Models::ObjectType.book)
      .new(structural: { contains: [{ type: Cocina::Models::FileSetType.page,
                                      label: 'Book page',
                                      version: 1,
                                      externalIdentifier: 'abc123456',
                                      structural: {} },
                                    { type: Cocina::Models::FileSetType.image,
                                      label: 'Book page 2',
                                      version: 1,
                                      externalIdentifier: 'abc789012',
                                      structural: {} }] })
  end
  let(:cocina2) do
    build(:dro, id: druids[1], type: Cocina::Models::ObjectType.image)
      .new(structural:
                      { contains: [{ type: Cocina::Models::FileSetType.file,
                                     label: 'Map label',
                                     version: 1,
                                     externalIdentifier: 'xyz012345',
                                     structural: {} }] })
  end
  let(:cocina3) do
    build(:collection, id: druids[2])
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina2) }
  let(:object_client3) { instance_double(Dor::Services::Client::Object, find: cocina3) }

  let(:state_service) { instance_double(StateService, allows_modification?: true) }
  let(:buffer) { StringIO.new }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(BulkJobLog).to receive(:open).and_yield(buffer)
    allow(subject.ability).to receive(:can?).and_return(true)
    allow(StateService).to receive(:new).and_return(state_service)
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client2)
    allow(Dor::Services::Client).to receive(:object).with(druids[2]).and_return(object_client3)
    allow(object_client1).to receive(:update)
    allow(object_client2).to receive(:update)
    allow(object_client3).to receive(:update)
    allow(Argo::Indexer).to receive(:reindex_druid_remotely)
  end

  context 'when book object with image and page resource types' do
    it 'changes the resource with image type to page type and logs success' do
      subject.perform(bulk_action.id, params)
      expect(object_client1).to have_received(:update)
        .with(
          params: cocina_object_with_types(
            resource_types: [Cocina::Models::FileSetType.page, Cocina::Models::FileSetType.image]
          )
        )
      expect(buffer.string).to include "Successfully updated content type for #{druids[0]}"
    end
  end

  context 'when object resource types and content type are requested to change' do
    let(:params) do
      {
        druids: [druids[1]],
        current_resource_type: 'https://cocina.sul.stanford.edu/models/resources/file',
        new_content_type: 'https://cocina.sul.stanford.edu/models/map',
        new_resource_type: 'https://cocina.sul.stanford.edu/models/resources/image'
      }
    end

    it 'changes the content type to map and resource type' do
      subject.perform(bulk_action.id, params)
      expect(object_client2).to have_received(:update)
        .with(
          params: cocina_object_with_types(
            content_type: Cocina::Models::ObjectType.map,
            resource_types: [Cocina::Models::FileSetType.page, Cocina::Models::FileSetType.image]
          )
        )
    end
  end

  context 'when new content type is book (with a right-to-left reading direction)' do
    let(:params) do
      {
        druids: [druids[0]],
        current_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page',
        new_content_type: 'https://cocina.sul.stanford.edu/models/book',
        viewing_direction: 'right-to-left',
        new_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page'
      }
    end

    it 'sets the viewing direction' do
      subject.perform(bulk_action.id, params)
      expect(object_client1).to have_received(:update)
        .with(
          params: cocina_object_with_types(
            content_type: Cocina::Models::ObjectType.book,
            viewing_direction: 'right-to-left'
          )
        )
    end
  end

  context 'when new content type is image (with a right-to-left reading direction)' do
    let(:params) do
      {
        druids: [druids[0]],
        current_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page',
        new_content_type: 'https://cocina.sul.stanford.edu/models/image',
        viewing_direction: 'right-to-left',
        new_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page'
      }
    end

    it 'sets the viewing direction' do
      subject.perform(bulk_action.id, params)
      expect(object_client1).to have_received(:update)
        .with(
          params: cocina_object_with_types(
            content_type: Cocina::Models::ObjectType.image,
            viewing_direction: 'right-to-left'
          )
        )
    end
  end

  context 'when new content type is map' do
    let(:params) do
      {
        druids: [druids[0]],
        current_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page',
        new_content_type: 'https://cocina.sul.stanford.edu/models/map',
        viewing_direction: 'right-to-left',
        new_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page'
      }
    end

    it 'does not set any viewing direction' do
      subject.perform(bulk_action.id, params)
      expect(object_client1).to have_received(:update)
        .with(
          params: cocina_object_with_types(
            content_type: Cocina::Models::ObjectType.map
          )
        )
    end
  end

  context 'when a new resource type is provided but not a new content type' do
    let(:params) do
      {
        druids: [druids[0]],
        current_resource_type: '',
        new_content_type: '',
        new_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page'
      }
    end

    it 'raises an error' do
      expect { subject.perform(bulk_action.id, params) }.to raise_error 'Must provide a new content type when changing resource type.'
      expect(object_client1).not_to have_received(:update)
    end
  end

  context 'when a no types are entered in the form' do
    let(:params) do
      {
        druids: [druids[0]],
        current_resource_type: '',
        new_content_type: '',
        new_resource_type: ''
      }
    end

    it 'raises an error' do
      expect { subject.perform(bulk_action.id, params) }.to raise_error 'Must provide values for types.'
      expect(object_client1).not_to have_received(:update)
    end
  end

  context 'without structural metadata' do
    let(:structural) { {} }
    let(:params) do
      {
        druids: [druids[0]],
        current_resource_type: '',
        new_content_type: 'https://cocina.sul.stanford.edu/models/map',
        new_resource_type: ''
      }
    end

    it 'changes the content type only' do
      subject.perform(bulk_action.id, params)
      expect(object_client1).to have_received(:update)
        .with(params: cocina_object_with_types(content_type: Cocina::Models::ObjectType.map))
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

  context 'when druid is for a collection' do
    let(:params) do
      {
        druids: ['druid:ff123gg4567'],
        current_resource_type: '',
        new_content_type: 'https://cocina.sul.stanford.edu/models/media',
        new_resource_type: ''
      }
    end

    it 'does not update and logs an error' do
      subject.perform(bulk_action.id, params)
      expect(buffer.string).to include 'Object is a https://cocina.sul.stanford.edu/models/collection and cannot be updated'
      expect(object_client3).not_to have_received(:update)
    end
  end
end
