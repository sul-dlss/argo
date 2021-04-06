# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DroRightsForm do
  let(:instance) { described_class.new(model, default_rights: 'world') }
  let(:model) { instance_double(Cocina::Models::DRO) }

  describe '#validate' do
    subject { instance.validate(rights: option) }

    context 'for world access' do
      let(:option) { 'world' }

      it { is_expected.to be true }
    end

    context 'for cdl access' do
      let(:option) { 'cdl-stanford-nd' }

      it { is_expected.to be true }
    end

    context 'for something not in the list' do
      let(:option) { 'junk' }

      it { is_expected.to be false }
    end
  end

  describe '#rights' do
    subject { instance.rights }

    let(:model) { instance_double(Cocina::Models::DRO, access: cocina_access) }
    let(:cocina_access) do
      instance_double(Cocina::Models::DROAccess, access: access, download: download, readLocation: read_location)
    end
    let(:access) { 'world' }
    let(:download) { true }
    let(:read_location) { nil }

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

      it { is_expected.to eq 'citation-only' }
    end

    context 'with dark' do
      let(:access) { 'dark' }
      let(:download) { 'none' }

      it { is_expected.to eq 'dark' }
    end
  end

  describe '#rights_list' do
    it 'displays the rights list with (APO default)' do
      expect(instance.rights_list).to eq [['World (APO default)', 'world'],
                                          ['World (no-download)', 'world-nd'],
                                          %w[Stanford stanford],
                                          ['Stanford (no-download)', 'stanford-nd'],
                                          ['Controlled Digital Lending (no-download)', 'cdl-stanford-nd'],
                                          ['Location: Special Collections', 'loc:spec'],
                                          ['Location: Music Library', 'loc:music'],
                                          ['Location: Archive of Recorded Sound', 'loc:ars'],
                                          ['Location: Art Library', 'loc:art'],
                                          ['Location: Hoover Library', 'loc:hoover'],
                                          ['Location: Media & Microtext', 'loc:m&m'],
                                          ['Dark (Preserve Only)', 'dark'],
                                          ['Citation Only', 'citation-only']]
    end
  end
end
