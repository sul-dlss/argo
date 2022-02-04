# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplyModsMetadata do
  let(:mods) do
    <<~XML
      <mods xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://www.loc.gov/mods/v3" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
            <titleInfo>
              <title>Oral history with Jakob Spielmann</title>
            </titleInfo>
      </mods>
    XML
  end

  let(:apo_druid) { 'druid:999apo' }
  let(:existing_mods) { nil }
  let(:druid) { 'druid:bc123hv8998' }
  let(:log) { instance_double(File, puts: true) }
  let(:ability) { Ability.new(user) }
  let(:user) { build(:user) }
  let(:cocina) do
    instance_double(Cocina::Models::DRO, administrative: administrative, externalIdentifier: druid, version: 1)
  end
  let(:administrative) { instance_double(Cocina::Models::Administrative, hasAdminPolicy: apo_druid) }

  let(:action) do
    described_class.new(apo_druid: apo_druid,
                        mods: mods,
                        cocina: cocina,
                        existing_mods: existing_mods,
                        original_filename: 'testfile.xlsx',
                        ability: ability,
                        log: log)
  end

  let(:workflow_client) { instance_double(Dor::Workflow::Client, status: true) }

  before do
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
  end

  describe '#apply' do
    subject(:apply) { action.apply }

    let(:status_service) { instance_double(Dor::Workflow::Client::Status, info: { status_code: 9 }) }
    let(:object_client) do
      instance_double(Dor::Services::Client::Object, metadata: metadata_client)
    end
    let(:metadata_client) do
      instance_double(Dor::Services::Client::Metadata, update_mods: nil)
    end

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(workflow_client).to receive(:status).and_return(status_service)
    end

    context 'with permission' do
      before do
        allow(ability).to receive(:can?).and_return(true)
        allow(action).to receive(:log_error!)
      end

      it 'saves the metadata' do
        apply
        expect(metadata_client).to have_received(:update_mods)
        expect(action).not_to have_received(:log_error!)
      end
    end

    context 'without permission' do
      before do
        allow(ability).to receive(:can?).and_return(false)
      end

      it 'saves the metadata' do
        apply
        expect(metadata_client).not_to have_received(:update_mods)
      end
    end
  end

  describe 'version_object' do
    before do
      allow(workflow_client).to receive(:status).and_return(status_service)
    end

    let(:status_service) { instance_double(Dor::Workflow::Client::Status, info: { status_code: status_code }) }

    let(:status_code) { 6 }
    let(:workflow) { instance_double(DorObjectWorkflowStatus) }

    it 'writes a log error message if a version cannot be opened' do
      expect(DorObjectWorkflowStatus).to receive(:new).with(druid, version: 1).and_return(workflow)
      expect(workflow).to receive(:can_open_version?).and_return(false)

      action.send(:version_object)
      expect(log).to have_received(:puts).with("argo.bulk_metadata.bulk_log_unable_to_version #{druid}")
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

      it 'does not update the version' do
        expect(action).not_to receive(:commit_new_version)

        action.send(:version_object)
      end
    end

    it 'updates the version if the object is past the registered state' do
      expect(DorObjectWorkflowStatus).to receive(:new).with(druid, version: 1).and_return(workflow)
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
        identifier: druid,
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
