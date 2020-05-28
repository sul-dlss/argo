# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessForm do
  let(:instance) { described_class.new(model, apo) }
  let(:model) { instance_double(Cocina::Models::DRO, access: cocina_access) }
  let(:apo) { instantiate_fixture('zt570tx3016', Dor::AdminPolicyObject) }
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

  describe '#rights_list' do
    let(:rights_with_default) do
      [['World (APO default)', 'world'],
       ['World (no-download)', 'world-nd'],
       %w[Stanford stanford],
       ['Stanford (no-download)', 'stanford-nd'],
       ['Location: Special Collections', 'loc:spec'],
       ['Location: Music Library', 'loc:music'],
       ['Location: Archive of Recorded Sound', 'loc:ars'],
       ['Location: Art Library', 'loc:art'],
       ['Location: Hoover Library', 'loc:hoover'],
       ['Location: Media & Microtext', 'loc:m&m'],
       ['Dark (Preserve Only)', 'dark'],
       ['Citation Only', 'citation-only']]
    end

    it 'displays the rights list with (APO default)' do
      expect(instance.rights_list).to eq(rights_with_default)
    end
  end
end
