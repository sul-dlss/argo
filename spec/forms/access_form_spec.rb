# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessForm do
  let(:instance) { described_class.new(model) }
  let(:model) { instance_double(Cocina::Models::DRO, access: cocina_access) }
  let(:cocina_access) do
    instance_double(Cocina::Models::Access, access: access, download: download, readLocation: read_location)
  end
  let(:access) { 'world' }
  let(:download) { true }
  let(:read_location) { nil }

  describe '#rights' do
    subject { instance.rights }

    context 'with download is true' do
      it { is_expected.to eq 'world' }
    end

    context 'with download is false' do
      let(:download) { 'none' }

      it { is_expected.to eq 'world-nd' }
    end

    context 'with location access' do
      let(:access) { 'location-based' }
      let(:read_location) { 'music' }

      it { is_expected.to eq 'loc:music' }
    end

    context 'with citation only' do
      let(:access) { 'citation-only' }
      let(:download) { 'none' }

      it { is_expected.to eq 'none' }
    end

    context 'with dark' do
      let(:access) { 'dark' }
      let(:download) { 'none' }

      it { is_expected.to eq 'dark' }
    end
  end
end
