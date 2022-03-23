# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionChangeSet do
  let(:instance) { described_class.new(collection) }
  let(:druid) { 'druid:bc123df4567' }

  describe 'loading from cocina' do
    let(:collection) do
      Cocina::Models.build({
                             'label' => 'My Collection',
                             'version' => 1,
                             'type' => Cocina::Models::ObjectType.collection,
                             'externalIdentifier' => druid,
                             'description' => {
                               'title' => [{ 'value' => 'My Collection' }],
                               'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                             },
                             'access' => {
                               view: 'world',
                               copyright: 'This collection is in the Public Domain.',
                               useAndReproductionStatement: 'Must be used underwater',
                               license: 'https://creativecommons.org/licenses/by-nc-sa/3.0/legalcode'
                             },
                             'administrative' => {
                               hasAdminPolicy: 'druid:cg532dg5405'
                             },
                             'identification' => {}
                           })
    end

    describe '#copyright' do
      subject { instance.copyright }

      it { is_expected.to eq 'This collection is in the Public Domain.' }
    end

    describe '#use_statement' do
      subject { instance.use_statement }

      it { is_expected.to eq 'Must be used underwater' }
    end

    describe '#license' do
      subject { instance.license }

      it { is_expected.to eq 'https://creativecommons.org/licenses/by-nc-sa/3.0/legalcode' }
    end
  end
end
