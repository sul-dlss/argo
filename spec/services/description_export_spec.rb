# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DescriptionExport do
  subject(:run) { described_class.export(source_id:, description:) }

  let(:source_id) { 'sul:123' }
  let(:description) do
    Cocina::Models::Description.new(
      { title: [{ value: 'Stored title' }], purl: 'https://purl.stanford.edu/zt570qh4444' }
    )
  end

  it 'rectangularizes the item' do
    expect(run).to eq('source_id' => 'sul:123', 'title1.value' => 'Stored title', 'purl' => 'https://purl.stanford.edu/zt570qh4444')
  end
end
