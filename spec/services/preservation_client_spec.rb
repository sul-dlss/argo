# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PreservationClient do
  describe '#current_version' do
    let(:bare_druid) { 'oo666oo1234' }
    let(:full_druid) { "druid:#{bare_druid}" }

    let(:valid_response) do
      {
        'id': 666,
        'druid': full_druid,
        'current_version': 3,
        'created_at': '2019-09-06T13:01:29.076Z',
        'updated_at': '2019-09-15T13:01:29.076Z',
        'preservation_policy_id': 1
      }
    end

    context 'when druid has "druid:" prefix' do
      before do
        stub_request(:get, "#{Settings.preservation_catalog.url}/objects/#{full_druid}.json")
          .to_return(status: 200, body: JSON.generate(valid_response), headers: { 'Content-Type' => 'application/json' })
      end

      it 'gets the current version as an integer' do
        expect(subject.current_version(full_druid)).to eq 3
      end
    end

    context 'when druid is bare (without "druid:" prefix)' do
      before do
        stub_request(:get, "#{Settings.preservation_catalog.url}/objects/#{bare_druid}.json")
          .to_return(status: 200, body: JSON.generate(valid_response), headers: { 'Content-Type' => 'application/json' })
      end

      it 'gets the current version as an integer' do
        expect(subject.current_version(bare_druid)).to eq 3
      end
    end

    context 'when there is a Faraday ClientError' do
      before do
        stub_request(:get, "#{Settings.preservation_catalog.url}/objects/#{bare_druid}.json")
          .to_raise(Faraday::TimeoutError.new('my message'))
      end

      it 'raises ResponseError' do
        errmsg = 'HTTP GET to https://example.org/prescat/objects/oo666oo1234.json failed with Faraday::TimeoutError: my message'
        expect { subject.current_version(bare_druid) }.to raise_error(PreservationClient::ResponseError, errmsg)
      end
    end

    context 'when response code from preservation catalog is not 200' do
      before do
        stub_request(:get, "#{Settings.preservation_catalog.url}/objects/#{bare_druid}.json")
          .to_return(status: 404, body: "{ foo: 'bar' }", headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises ResponseError' do
        errmsg = "Got 404 retrieving version from Preservation Catalog at https://example.org/prescat/objects/oo666oo1234.json: { foo: 'bar' }"
        expect { subject.current_version(bare_druid) }.to raise_error(PreservationClient::ResponseError, errmsg)
      end
    end
  end
end
