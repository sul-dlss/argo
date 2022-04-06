# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImportStructuralJob, type: :job do
  subject(:job) { described_class.new }

  let(:bulk_action) { create(:bulk_action, action_type: 'ImportStructuralJob') }
  let(:log_buffer) { StringIO.new }
  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1, update: true) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina2, update: true) }

  before do
    allow(job).to receive(:bulk_action).and_return(bulk_action)
    allow(BulkJobLog).to receive(:open).and_yield(log_buffer)
    allow(Ability).to receive(:new).and_return(ability)
    allow(Dor::Services::Client).to receive(:object).with(druid1).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druid2).and_return(object_client2)
    allow(Argo::Indexer).to receive(:reindex_druid_remotely)
  end

  describe '#perform' do
    let(:file_path) { File.join(file_fixture_path, 'bulk_upload_structural.csv') }
    let(:csv_file) { File.read(file_path) }

    let(:druid1) { 'druid:zp968gy7494' }
    let(:druid2) { 'druid:bc234fg7890' }
    let(:cocina1) do
      build(:dro, id: druid1, version: 6, type: Cocina::Models::ObjectType.map)
        .new(structural: {
               contains: [
                 {
                   type: Cocina::Models::FileSetType.image,
                   externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/jt667tw2770-0001',
                   label: '',
                   version: 6,
                   structural: {
                     contains: [
                       {
                         type: Cocina::Models::ObjectType.file,
                         externalIdentifier: 'https://cocina.sul.stanford.edu/file/jt667tw2770-0001/jt667tw2770_00_0001.tif',
                         label: 'jt667tw2770_00_0001.tif',
                         filename: 'jt667tw2770_00_0001.tif',
                         size: 193_090_740,
                         version: 6,
                         hasMimeType: 'image/tiff',
                         hasMessageDigests: [
                           { type: 'sha1', digest: 'd71f1b739d4b3ff2bf199c8e3452a16c7a6609f0' },
                           { type: 'md5', digest: 'a695ccc6ed7a9c905ba917d7c284854e' }
                         ],
                         access: { view: 'world', download: 'world' },
                         administrative: { publish: false, sdrPreserve: true, shelve: false },
                         presentation: { height: 6610, width: 9736 }
                       }, {
                         type: Cocina::Models::ObjectType.file,
                         externalIdentifier: 'https://cocina.sul.stanford.edu/file/jt667tw2770-0001/jt667tw2770_05_0001.jp2',
                         label: 'jt667tw2770_05_0001.jp2',
                         filename: 'jt667tw2770_05_0001.jp2',
                         size: 12_141_770,
                         version: 6,
                         hasMimeType: 'image/jp2',
                         hasMessageDigests: [
                           { type: 'sha1', digest: 'b6632c33619e3dd6268eb1504580285670f4c3b8' },
                           { type: 'md5', digest: '9f74085aa752de7404d31cb6bcc38a56' }
                         ],
                         access: { view: 'world', download: 'world' },
                         administrative: { publish: true, sdrPreserve: true, shelve: true },
                         presentation: { height: 6610, width: 9736 }
                       }
                     ]
                   }
                 }
               ],
               hasMemberOrders: [],
               isMemberOf: ['druid:zb871zd0767']
             })
    end

    let(:cocina2) do
      build(:dro, id: druid2, version: 6, type: Cocina::Models::ObjectType.map)
        .new(structural: {
               contains: [
                 {
                   type: Cocina::Models::FileSetType.image,
                   externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/jt667tw2770-0001',
                   label: '',
                   version: 6,
                   structural: {
                     contains: [
                       {
                         type: Cocina::Models::ObjectType.file,
                         externalIdentifier: 'https://cocina.sul.stanford.edu/file/jt667tw2770-0001/jt667tw2770_00_0001.tif',
                         label: 'jt667tw2770_00_0001.tif',
                         filename: 'jt667tw2770_00_0001.tif',
                         size: 193_090_740,
                         version: 6,
                         hasMimeType: 'image/tiff',
                         hasMessageDigests: [
                           { type: 'sha1', digest: 'd71f1b739d4b3ff2bf199c8e3452a16c7a6609f0' },
                           { type: 'md5', digest: 'a695ccc6ed7a9c905ba917d7c284854e' }
                         ],
                         access: { view: 'world', download: 'world' },
                         administrative: { publish: false, sdrPreserve: true, shelve: false },
                         presentation: { height: 6610, width: 9736 }
                       }, {
                         type: Cocina::Models::ObjectType.file,
                         externalIdentifier: 'https://cocina.sul.stanford.edu/file/jt667tw2770-0001/jt667tw2770_05_0001.jp2',
                         label: 'jt667tw2770_05_0001.jp2',
                         filename: 'jt667tw2770_05_0001.jp2',
                         size: 12_141_770,
                         version: 6,
                         hasMimeType: 'image/jp2',
                         hasMessageDigests: [
                           { type: 'sha1', digest: 'b6632c33619e3dd6268eb1504580285670f4c3b8' },
                           { type: 'md5', digest: '9f74085aa752de7404d31cb6bcc38a56' }
                         ],
                         access: { view: 'world', download: 'world' },
                         administrative: { publish: true, sdrPreserve: true, shelve: true },
                         presentation: { height: 6610, width: 9736 }
                       }
                     ]
                   }
                 }
               ],
               hasMemberOrders: [],
               isMemberOf: ['druid:zb871zd0767']
             })
    end

    context 'when happy path' do
      let(:ability) { instance_double(Ability, can?: true) }

      before do
        job.perform(bulk_action.id, csv_file: csv_file)
      end

      it 'updates the structural for each druid' do
        expect(object_client1).to have_received(:update)
        expect(object_client2).to have_received(:update)
        expect(bulk_action.druid_count_total).to eq 2
        expect(bulk_action.druid_count_success).to eq 2
        expect(bulk_action.druid_count_fail).to eq 0
      end
    end

    context 'when not authorized' do
      let(:ability) { instance_double(Ability, can?: false) }

      before do
        job.perform(bulk_action.id, csv_file: csv_file)
      end

      it 'does not update the structural for any druid' do
        expect(object_client1).not_to have_received(:update)
        expect(object_client2).not_to have_received(:update)
        expect(bulk_action.druid_count_total).to eq 2
        expect(bulk_action.druid_count_success).to eq 0
        expect(bulk_action.druid_count_fail).to eq 2
      end
    end

    context 'when client throws an error' do
      let(:ability) { instance_double(Ability, can?: true) }

      before do
        allow(object_client1).to receive(:update).and_raise('borkne')
        allow(object_client2).to receive(:update).and_raise('borkne')

        job.perform(bulk_action.id, csv_file: csv_file)
      end

      it 'does not update the structural for any druid' do
        expect(bulk_action.druid_count_total).to eq 2
        expect(bulk_action.druid_count_success).to eq 0
        expect(bulk_action.druid_count_fail).to eq 2
      end
    end
  end
end
