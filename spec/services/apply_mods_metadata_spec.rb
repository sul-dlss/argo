# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplyModsMetadata do
  let(:apo_druid) {}
  let(:mods_node) {}
  let(:item) { instance_double(Dor::Item, pid: 'druid:123abc') }
  let(:log) { instance_double(File, puts: true) }
  let(:action) do
    described_class.new(apo_druid: apo_druid,
                        mods_node: mods_node,
                        item: item,
                        original_filename: 'testfile.xlsx',
                        user_login: 'username',
                        log: log)
  end

  describe 'version_object' do
    before do
      allow(Dor::StatusService).to receive(:new).and_return(stub_service)
    end

    let(:stub_service) { instance_double(Dor::StatusService, status_info: { status_code: status_code }) }
    let(:status_code) { 6 }
    let(:workflow) { instance_double(DorObjectWorkflowStatus) }

    it 'writes a log error message if a version cannot be opened' do
      expect(DorObjectWorkflowStatus).to receive(:new).with(item.pid).and_return(workflow)
      expect(workflow).to receive(:can_open_version?).and_return(false)

      action.send(:version_object)
      expect(log).to have_received(:puts).with("argo.bulk_metadata.bulk_log_unable_to_version #{item.pid}")
    end

    context 'the object is in the registered state' do
      let(:status_code) { 1 }

      it 'does not update the version' do
        expect(action).not_to receive(:commit_new_version)

        action.send(:version_object)
      end
    end

    context 'the object is in the opened state' do
      let(:status_code) { 9 }

      it 'does not update the version ' do
        expect(action).not_to receive(:commit_new_version)

        action.send(:version_object)
      end
    end

    it 'updates the version if the object is past the registered state' do
      expect(DorObjectWorkflowStatus).to receive(:new).with(item.pid).and_return(workflow)
      expect(workflow).to receive(:can_open_version?).and_return(true)
      expect(action).to receive(:commit_new_version)

      action.send(:version_object)
    end
  end

  describe '#commit_new_version' do
    before do
      allow(VersionService).to receive(:open)
    end

    it 'opens a new minor version with filename and username' do
      action.send(:commit_new_version)

      expect(VersionService).to have_received(:open).with(
        identifier: item.pid,
        significance: 'minor',
        description: 'Descriptive metadata upload from testfile.xlsx',
        opening_user_name: 'username'
      )
    end
  end

  describe 'status_ok?' do
    (0..9).each do |i|
      it "correctly queries the status of DOR objects (:status_code #{i})" do
        allow(action).to receive(:status).and_return(i)
        if [1, 6, 7, 8, 9].include?(i)
          expect(action.send(:status_ok?)).to be_truthy
        else
          expect(action.send(:status_ok?)).to be_falsy
        end
      end
    end
  end

  describe 'in_accessioning?' do
    (0..9).each do |i|
      it "returns true for DOR objects that are currently in acccessioning, false otherwise (:status_code #{i})" do
        allow(action).to receive(:status).and_return(i)
        if [2, 3, 4, 5].include?(i)
          expect(action.send(:in_accessioning?)).to be_truthy
        else
          expect(action.send(:in_accessioning?)).to be_falsy
        end
      end
    end
  end

  describe 'accessioned?' do
    (0..9).each do |i|
      it "returns true for DOR objects that are acccessioned, false otherwise (:status_code #{i})" do
        allow(action).to receive(:status).and_return(i)
        if [6, 7, 8].include?(i)
          expect(action.send(:accessioned?)).to be_truthy
        else
          expect(action.send(:accessioned?)).to be_falsy
        end
      end
    end
  end
end
