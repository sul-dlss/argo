# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetContentTypeJob do
  subject(:job) { described_class.new(bulk_action.id, **params) }

  let(:druid) { 'druid:bb111cc2222' }
  let(:bulk_action) { create(:bulk_action) }

  let(:job_item) do
    described_class::SetContentTypeJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive(:close_version_if_needed!)
      allow(job_item).to receive(:check_update_ability?).and_return(true)
    end
  end

  let(:cocina_object) do
    build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.book)
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

  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_object) }

  let(:log) { StringIO.new }

  before do
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
    allow(described_class::SetContentTypeJobItem).to receive(:new).and_return(job_item)
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(Repository).to receive(:store)
  end

  context 'when book object with image and page resource types' do
    let(:params) do
      {
        druids: [druid],
        current_resource_type: 'https://cocina.sul.stanford.edu/models/resources/image',
        new_content_type: 'https://cocina.sul.stanford.edu/models/book',
        viewing_direction: 'left-to-right',
        new_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page'
      }
    end

    it 'performs the job' do
      job.perform_now

      expect(job_item).to have_received(:check_update_ability?)
      expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Updating content type')
      expect(Repository).to have_received(:store)
        .with(cocina_object_with_types(
                resource_types: [Cocina::Models::FileSetType.page, Cocina::Models::FileSetType.image]
              ))
      expect(job_item).to have_received(:close_version_if_needed!)

      expect(log.string).to include "Successfully updated content type for #{druid}"
      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
      expect(bulk_action.druid_count_success).to eq(1)
    end
  end

  context 'when object resource types and content type are requested to change' do
    let(:params) do
      {
        druids: [druid],
        current_resource_type: 'https://cocina.sul.stanford.edu/models/resources/file',
        new_content_type: 'https://cocina.sul.stanford.edu/models/map',
        new_resource_type: 'https://cocina.sul.stanford.edu/models/resources/image'
      }
    end

    let(:cocina_object) do
      build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.image)
        .new(structural:
                        { contains: [{ type: Cocina::Models::FileSetType.file,
                                       label: 'Map label',
                                       version: 1,
                                       externalIdentifier: 'xyz012345',
                                       structural: {} }] })
    end

    it 'changes the content type to map and resource type' do
      job.perform_now

      expect(Repository).to have_received(:store)
        .with(cocina_object_with_types(
                content_type: Cocina::Models::ObjectType.map,
                resource_types: [Cocina::Models::FileSetType.page, Cocina::Models::FileSetType.image]
              ))
    end
  end

  context 'when new content type is book (with a right-to-left reading direction)' do
    let(:params) do
      {
        druids: [druid],
        current_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page',
        new_content_type: 'https://cocina.sul.stanford.edu/models/book',
        viewing_direction: 'right-to-left',
        new_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page'
      }
    end

    it 'sets the viewing direction' do
      job.perform_now

      expect(Repository).to have_received(:store)
        .with(cocina_object_with_types(
                content_type: Cocina::Models::ObjectType.book,
                viewing_direction: 'right-to-left'
              ))
    end
  end

  context 'when new content type is image (with a right-to-left reading direction)' do
    let(:params) do
      {
        druids: [druid],
        current_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page',
        new_content_type: 'https://cocina.sul.stanford.edu/models/image',
        viewing_direction: 'right-to-left',
        new_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page'
      }
    end

    it 'sets the viewing direction' do
      subject.perform_now

      expect(Repository).to have_received(:store)
        .with(cocina_object_with_types(
                content_type: Cocina::Models::ObjectType.image,
                viewing_direction: 'right-to-left'
              ))
    end
  end

  context 'when new content type is map' do
    let(:params) do
      {
        druids: [druid],
        current_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page',
        new_content_type: 'https://cocina.sul.stanford.edu/models/map',
        viewing_direction: 'right-to-left',
        new_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page'
      }
    end

    it 'does not set any viewing direction' do
      subject.perform_now

      expect(Repository).to have_received(:store)
        .with(cocina_object_with_types(
                content_type: Cocina::Models::ObjectType.map
              ))
    end
  end

  context 'when a new resource type is provided but not a new content type' do
    let(:params) do
      {
        druids: [druid],
        current_resource_type: '',
        new_content_type: '',
        new_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page'
      }
    end

    it 'does not update' do
      expect { job.perform_now }.to raise_error 'Must provide a new content type when changing resource type.'

      expect(Repository).not_to have_received(:store)
    end
  end

  context 'when a no types are entered in the form' do
    let(:params) do
      {
        druids: [druid],
        current_resource_type: '',
        new_content_type: '',
        new_resource_type: ''
      }
    end

    it 'raises an error' do
      expect { job.perform_now }.to raise_error 'Must provide values for types.'

      expect(Repository).not_to have_received(:store)
    end
  end

  context 'without structural metadata' do
    let(:cocina_object) { build(:dro_with_metadata, id: druid, type: Cocina::Models::ObjectType.image) }

    let(:params) do
      {
        druids: [druid],
        current_resource_type: '',
        new_content_type: 'https://cocina.sul.stanford.edu/models/map',
        new_resource_type: ''
      }
    end

    it 'changes the content type only' do
      job.perform_now

      expect(Repository).to have_received(:store)
        .with(cocina_object_with_types(content_type: Cocina::Models::ObjectType.map))
    end
  end

  context 'when not authorized to manage object' do
    let(:params) do
      {
        druids: [druid],
        current_resource_type: 'https://cocina.sul.stanford.edu/models/resources/image',
        new_content_type: 'https://cocina.sul.stanford.edu/models/book',
        viewing_direction: 'left-to-right',
        new_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page'
      }
    end

    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not update the object' do
      job.perform_now

      expect(Repository).not_to have_received(:store)
    end
  end

  context 'when druid a collection' do
    let(:params) do
      {
        druids: [druid],
        current_resource_type: 'https://cocina.sul.stanford.edu/models/resources/image',
        new_content_type: 'https://cocina.sul.stanford.edu/models/book',
        viewing_direction: 'left-to-right',
        new_resource_type: 'https://cocina.sul.stanford.edu/models/resources/page'
      }
    end

    let(:cocina_object) { build(:collection_with_metadata, id: druid) }

    it 'does not update and logs an error' do
      job.perform_now

      expect(Repository).not_to have_received(:store)
      expect(log.string).to include 'Object is a https://cocina.sul.stanford.edu/models/collection and cannot be updated'

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end
end
