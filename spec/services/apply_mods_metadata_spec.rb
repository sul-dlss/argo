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

  let(:apo_druid) { 'druid:xx666zz7777' }
  let(:druid) { 'druid:bc123hv8998' }
  let(:log) { instance_double(File, puts: true) }
  let(:ability) { Ability.new(user) }
  let(:user) { build(:user) }
  let(:cocina) do
    build(:dro_with_metadata, id: druid, admin_policy_id: apo_druid)
  end

  let(:updated_cocina) do
    cocina.new(
      description: {
        title: [
          { value: 'Oral history with Jakob Spielmann' }
        ],
        purl: 'https://sul-purl-stage.stanford.edu/bc123hv8998'
      }
    )
  end

  let(:action) do
    described_class.new(apo_druid:,
                        mods:,
                        cocina:,
                        original_filename: 'testfile.xlsx',
                        ability:,
                        log:)
  end

  let(:workflow_client) { instance_double(Dor::Workflow::Client, status: true) }

  before do
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
  end

  describe '#apply' do
    subject(:apply) { action.apply }

    let(:status_service) { instance_double(Dor::Workflow::Client::Status, status_code: 9) }
    let(:object_client) do
      instance_double(Dor::Services::Client::Object)
    end

    before do
      allow(workflow_client).to receive(:status).and_return(status_service)
      allow(object_client).to receive(:update)
    end

    context 'with permission' do
      before do
        allow(ability).to receive(:can?).and_return(true)
        allow(action).to receive(:log_error!)
      end

      context 'when save works' do
        before do
          allow(Dor::Services::Client).to receive(:object).and_return(object_client)
        end

        it 'saves the metadata' do
          apply
          expect(object_client).to have_received(:update).with(params: updated_cocina)
          expect(action).not_to have_received(:log_error!)
        end
      end

      context 'when save fails' do
        before do
          stub_request(:patch, "#{Settings.dor_services.url}/v1/objects/#{druid}")
            .to_return(status: 422, body: json_response, headers: { 'content-type' => 'application/vnd.api+json' })
        end

        let(:json_response) do
          <<~JSON
            {"errors":
              [{
                "status":"422",
                "title":"problem",
                "detail":"broken"
              }]
            }
          JSON
        end

        it 'logs the error' do
          apply
          expect(log).to have_received(:puts).with('argo.bulk_metadata.bulk_log_unexpected_response druid:bc123hv8998 problem (broken)')
        end
      end

      context 'when ValidationError' do
        before do
          allow(action).to receive(:cocina_description).and_raise(Cocina::Models::ValidationError, 'Bad type')
        end

        it 'logs the error' do
          apply
          expect(log).to have_received(:puts).with('argo.bulk_metadata.bulk_log_validation_error druid:bc123hv8998 Bad type')
        end
      end

      context 'when unchanged' do
        let(:action) do
          described_class.new(apo_druid:,
                              mods:,
                              cocina: updated_cocina,
                              original_filename: 'testfile.xlsx',
                              ability:,
                              log:)
        end

        it 'logs and skips' do
          apply
          expect(object_client).not_to have_received(:update)
          expect(log).to have_received(:puts).with('argo.bulk_metadata.bulk_log_skipped_mods druid:bc123hv8998')
        end
      end
    end

    context 'without permission' do
      before do
        allow(ability).to receive(:can?).and_return(false)
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      end

      it 'saves the metadata' do
        apply
        expect(object_client).not_to have_received(:update)
      end
    end
  end

  describe 'version_object' do
    before do
      allow(workflow_client).to receive(:status).and_return(status_service)
    end

    let(:status_service) { instance_double(Dor::Workflow::Client::Status, status_code:) }

    let(:status_code) { 6 }
    let(:workflow) { instance_double(DorObjectWorkflowStatus) }

    it 'writes a log error message if a version cannot be opened' do
      expect(DorObjectWorkflowStatus).to receive(:new).with(druid, version: 1).and_return(workflow)
      expect(workflow).to receive(:can_open_version?).and_return(false)

      action.send(:version_object)
      expect(log).to have_received(:puts).with("argo.bulk_metadata.bulk_log_unable_to_version #{druid}")
    end

    context 'when the object is in the registered state' do
      let(:status_code) { 1 }

      it 'does not update the version' do
        expect(action).not_to receive(:commit_new_version)

        action.send(:version_object)
      end
    end

    context 'when the object is in the opened state' do
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
    let(:object_client) { instance_double(Dor::Services::Client::Object, version: version_client) }
    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, open: true) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    it 'opens a new minor version with filename and username' do
      action.send(:commit_new_version)

      expect(version_client).to have_received(:open).with(
        description: 'Descriptive metadata upload from testfile.xlsx',
        opening_user_name: user.sunetid
      )
    end
  end

  describe 'status_ok?' do
    10.times do |i|
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
    10.times do |i|
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
    10.times do |i|
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
