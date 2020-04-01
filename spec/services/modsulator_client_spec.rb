# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ModsulatorClient do
  let(:log_file) { double(puts: nil) }

  describe '.normalize_mods' do
    subject(:response) do
      described_class.normalize_mods(uploaded_filename: file_path, pretty_filename: 'foo', log: log_file)
    end

    let(:file_path) { "#{::Rails.root}/spec/fixtures/crowdsourcing_bridget_1.xml" }

    context 'when the modsulator returns a response' do
      before do
        stub_request(:post, Settings.normalizer_url).to_return(body: 'abc')
      end

      it { is_expected.to eq 'abc' }
    end

    context 'when the modsulator returns an error' do
      before do
        stub_request(:post, Settings.normalizer_url).to_return(status: 500)
      end

      it 'handles HTTP errors' do
        expect(response).to be_blank
        expect(log_file).to have_received(:puts).with(/argo.bulk_metadata.bulk_log_internal_error/)
      end
    end
  end

  describe '.convert_spreadsheet_to_mods' do
    subject(:response) do
      described_class.convert_spreadsheet_to_mods(uploaded_filename: file_path, pretty_filename: 'foo', log: log_file)
    end

    let(:file_path) { "#{::Rails.root}/spec/fixtures/crowdsourcing_bridget_1.xlsx" }

    before do
      stub_request(:post, Settings.modsulator_url).to_return(body: 'abc')
    end

    it { is_expected.to eq 'abc' }
  end
end
