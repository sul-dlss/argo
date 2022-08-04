# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegistrationCsvConverter do
  let(:results) { described_class.convert(csv_string:, params:) }

  let(:params) { {} }

  let(:expected_cocina) do
    Cocina::Models.build_request(
      {
        cocinaVersion: Cocina::Models::VERSION,
        type: Cocina::Models::ObjectType.book,
        label: 'My new object',
        version: 1,
        access: { view: 'world', download: 'world', controlledDigitalLending: false },
        administrative: { hasAdminPolicy: 'druid:bc123df4567' },
        identification: { sourceId: 'foo:123' },
        structural: { isMemberOf: ['druid:bk024qs1808'] }
      }
    )
  end

  context 'when all values provided in CSV' do
    let(:csv_string) do
      <<~CSV
        administrative_policy_object,collection,initial_workflow,content_type,source_id,label,rights_view,rights_download,tags,tags
        druid:bc123df4567,druid:bk024qs1808,accessionWF,book,foo:123,My new object,world,world,csv : test,Project : two
        xdruid:dj123qx4567,druid:bk024qs1808,accessionWF,book,foo:123,A label,world,world
      CSV
    end

    it 'returns result with model, workflow, and tags' do
      expect(results.size).to be 2
      expect(results.first.success?).to be true
      expect(results.first.value![:workflow]).to eq('accessionWF')
      expect(results.first.value![:tags]).to eq(['csv : test', 'Project : two'])
      expect(results.first.value![:model]).to eq(expected_cocina)
      expect(results.second.success?).to be false
    end
  end

  context 'when values provided in params' do
    let(:csv_string) do
      <<~CSV
        source_id,label
        foo:123,My new object
        foo:123,A label
      CSV
    end

    let(:params) do
      {
        administrative_policy_object: 'druid:bc123df4567',
        collection: 'druid:bk024qs1808',
        initial_workflow: 'accessionWF',
        content_type: Cocina::Models::ObjectType.book,
        rights_view: 'world',
        rights_download: 'world',
        tags: ['csv : test', 'Project : two']
      }
    end

    it 'returns result with model, workflow, and tags' do
      expect(results.size).to be 2
      expect(results.first.success?).to be true
      expect(results.first.value![:workflow]).to eq('accessionWF')
      expect(results.first.value![:tags]).to eq(['csv : test', 'Project : two'])
      expect(results.first.value![:model]).to eq(expected_cocina)
    end
  end

  context 'when no rights provided in params' do
    let(:csv_string) do
      <<~CSV
        source_id,label
        foo:123,My new object
      CSV
    end

    let(:params) do
      {
        administrative_policy_object: 'druid:bc123df4567',
        collection: 'druid:bk024qs1808',
        initial_workflow: 'accessionWF',
        content_type: Cocina::Models::ObjectType.book,
        tags: ['csv : test', 'Project : two']
      }
    end

    it 'uses default rights' do
      expect(results.size).to be 1
      expect(results.first.success?).to be true
      expect(results.first.value![:model]).to eq(expected_cocina.new(access: {}))
    end
  end

  context 'when params have rights_view citation-only but no rights_download' do
    let(:csv_string) do
      <<~CSV
        source_id,label
        foo:123,My new object
      CSV
    end

    let(:params) do
      {
        administrative_policy_object: 'druid:bc123df4567',
        collection: 'druid:bk024qs1808',
        initial_workflow: 'accessionWF',
        content_type: Cocina::Models::ObjectType.book,
        rights_view: 'citation-only',
        tags: ['csv : test', 'Project : two']
      }
    end

    it 'returns result with access citation-only model' do
      expect(results.size).to be 1
      expect(results.first.success?).to be true
      expect(results.first.value![:model]).to eq(expected_cocina.new(access: { 'view' => 'citation-only', 'download' => 'none' }))
    end
  end

  context 'when CSV has rights_view citation-only but no rights_download' do
    let(:csv_string) do
      <<~CSV
        source_id,label,rights_view
        foo:123,My new object,citation-only
      CSV
    end

    let(:params) do
      {
        administrative_policy_object: 'druid:bc123df4567',
        collection: 'druid:bk024qs1808',
        initial_workflow: 'accessionWF',
        content_type: Cocina::Models::ObjectType.book,
        tags: ['csv : test', 'Project : two']
      }
    end

    it 'returns result with access citation-only model' do
      expect(results.size).to be 1
      expect(results.first.success?).to be true
      expect(results.first.value![:model]).to eq(expected_cocina.new(access: { 'view' => 'citation-only', 'download' => 'none' }))
    end
  end
end
