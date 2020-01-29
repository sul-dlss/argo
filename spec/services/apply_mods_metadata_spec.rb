# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplyModsMetadata do
  let(:mods_node) {}
  let(:apo_druid) { 'druid:999apo' }
  let(:desc_metadata) { instance_double(Dor::DescMetadataDS, content: '<xml/>', 'content=': true) }
  let(:item) do
    instance_double(Dor::Item,
                    descMetadata: desc_metadata,
                    pid: 'druid:123abc',
                    current_version: 1,
                    admin_policy_object_id: apo_druid,
                    save!: true)
  end
  let(:log) { instance_double(File, puts: true) }
  let(:ability) { Ability.new(user) }
  let(:user) { build(:user) }
  let(:action) do
    described_class.new(apo_druid: apo_druid,
                        mods_node: mods_node,
                        item: item,
                        original_filename: 'testfile.xlsx',
                        ability: ability,
                        log: log)
  end

  describe '#apply' do
    subject(:apply) { action.apply }

    let(:status_service) { instance_double(Dor::Workflow::Client::Status, info: { status_code: 9 }) }

    before do
      allow(Dor::Config.workflow.client).to receive(:status).and_return(status_service)
    end

    context 'with permission' do
      before do
        allow(ability).to receive(:can?).and_return(true)
        allow(action).to receive(:log_error!)
      end

      it 'saves the metadata' do
        apply
        expect(item).to have_received(:save!)
        expect(action).not_to have_received(:log_error!)
      end
    end

    context 'without permission' do
      before do
        allow(ability).to receive(:can?).and_return(false)
      end

      it 'saves the metadata' do
        apply
        expect(item).not_to have_received(:save!)
      end
    end
  end

  describe 'version_object' do
    before do
      allow(Dor::Config.workflow.client).to receive(:status).and_return(status_service)
    end

    let(:status_service) { instance_double(Dor::Workflow::Client::Status, info: { status_code: status_code }) }

    let(:status_code) { 6 }
    let(:workflow) { instance_double(DorObjectWorkflowStatus) }

    it 'writes a log error message if a version cannot be opened' do
      expect(DorObjectWorkflowStatus).to receive(:new).with(item.pid, version: 1).and_return(workflow)
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
      expect(DorObjectWorkflowStatus).to receive(:new).with(item.pid, version: 1).and_return(workflow)
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
        opening_user_name: user.sunetid
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
      it "returns true for DOR objects that are currently in accessioning, false otherwise (:status_code #{i})" do
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
      it "returns true for DOR objects that are accessioned, false otherwise (:status_code #{i})" do
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
