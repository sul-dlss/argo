# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionRightsForm do
  let(:instance) { described_class.new(model, default_rights: 'world') }
  let(:model) { instance_double(Cocina::Models::Collection) }

  describe '#validate' do
    subject { instance.validate(rights: option) }

    context 'for world access' do
      let(:option) { 'world' }

      it { is_expected.to be true }
    end

    context 'for cdl access' do
      let(:option) { 'cdl-stanford-nd' }

      it { is_expected.to be false }
    end
  end

  describe '#rights' do
    subject { instance.rights }

    let(:model) { instance_double(Cocina::Models::Collection, access: cocina_access) }
    let(:cocina_access) do
      instance_double(Cocina::Models::Access, access: access)
    end
    let(:access) { 'world' }

    it { is_expected.to eq 'world' }

    context 'with dark' do
      let(:access) { 'dark' }

      it { is_expected.to eq 'dark' }
    end
  end

  describe '#rights_list' do
    it 'displays the rights list with (APO default)' do
      expect(instance.rights_list).to eq [['World (APO default)', 'world'],
                                          ['Dark (Preserve Only)', 'dark']]
    end
  end
end
