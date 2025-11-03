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

  let(:object_client) do
    instance_double(Dor::Services::Client::Object, version: cocina)
  end
  let(:version_service) { instance_double(VersionService, open?: false, openable?: true) }

  before do
    allow(VersionService).to receive(:new).and_return(version_service)
  end

  describe '#apply' do
    subject(:apply) { action.apply }

    before do
      allow(object_client).to receive(:update)
      allow(version_service).to receive(:open).and_return(cocina)
    end

    context 'with permission' do
      before do
        allow(ability).to receive(:can?).and_return(true)
      end

      context 'when successful' do
        before do
          allow(Dor::Services::Client).to receive(:object).and_return(object_client)
        end

        it 'updates the metadata' do
          apply
          expect(version_service).to have_received(:open)
          expect(object_client).to have_received(:update).with(params: updated_cocina)
        end
      end

      context 'when save fails' do
        before do
          stub_request(:patch, "#{Settings.dor_services.url}/v1/objects/#{druid}")
            .to_return(status: 422, body: json_response, headers: { 'content-type' => 'application/vnd.api+json' })
          allow(action).to receive(:log_error!)
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

      context 'when object is not updatable' do
        let(:version_service) { instance_double(VersionService, open?: false, openable?: false) }

        it 'logs and skips' do
          apply
          expect(object_client).not_to have_received(:update)
          expect(log).to have_received(:puts).with('argo.bulk_metadata.bulk_log_skipped_mods druid:bc123hv8998')
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

      it 'does not update the metadata' do
        apply
        expect(object_client).not_to have_received(:update)
      end
    end
  end

  describe 'version_object' do
    context 'when item is open' do
      let(:version_service) { instance_double(VersionService, open?: true, openable?: false) }

      it 'does not open a new version' do
        expect(action).not_to receive(:open)
        action.send(:version_object)
      end
    end

    context 'when item is not open' do
      let(:version_service) { instance_double(VersionService, open?: false, openable?: true) }

      before do
        allow(version_service).to receive(:open).and_return(cocina)
      end

      it 'opens a new version' do
        action.send(:version_object)
        expect(version_service).to have_received(:open).with(
          druid:,
          description: 'Updated descriptive metadata from testfile.xlsx',
          opening_user_name: user.sunetid
        )
      end
    end
  end
end
