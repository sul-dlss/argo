# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTags do
  let(:dor_object) { instantiate_fixture('druid:qq613vj0238') }
  describe '.from_dor_object' do
    it 'creates a ReleaseTag for each element from an objects identityMetadata' do
      expect(described_class.from_dor_object(dor_object).count).to eq 2
      described_class.from_dor_object(dor_object).each do |release_tag|
        expect(release_tag).to be_an ReleaseTag
      end
    end
  end
end
