# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrDocument, type: :model do
  describe '#datastreams' do
    subject(:datastreams) { doc.datastreams }

    let(:doc) do
      described_class.new('ds_specs_ssim' => [
                            'DC|X|text/xml|0|475|Dublin Core Record for this object',
                            'RELS-EXT|X|application/rdf+xml|0|821|Fedora Object-to-Object Relationship Metadata',
                            'identityMetadata|M|text/xml|0|635|Identity Metadata',
                            'rightsMetadata|M|text/xml|4|652|Rights metadata',
                            'descMetadata|M|text/xml|3|5988|Descriptive Metadata',
                            'workflows|E|application/xml|0|10780|Workflows'
                          ])
    end

    it 'excludes workflows' do
      expect(datastreams).to eq [
        { control_group: 'X',
          dsid: 'DC',
          label: 'Dublin Core Record for this object',
          mime_type: 'text/xml',
          size: '475',
          version: '0' },
        { control_group: 'X',
          dsid: 'RELS-EXT',
          label: 'Fedora Object-to-Object Relationship Metadata',
          mime_type: 'application/rdf+xml',
          size: '821',
          version: '0' },
        { control_group: 'M',
          dsid: 'identityMetadata',
          label: 'Identity Metadata',
          mime_type: 'text/xml',
          size: '635',
          version: '0' },
        { control_group: 'M',
          dsid: 'rightsMetadata',
          label: 'Rights metadata',
          mime_type: 'text/xml',
          size: '652',
          version: '4' },
        { control_group: 'M',
          dsid: 'descMetadata',
          label: 'Descriptive Metadata',
          mime_type: 'text/xml',
          size: '5988',
          version: '3' }
      ]
    end
  end

  describe 'get_versions' do
    it 'builds a version hash' do
      data = []
      data << '1;1.0.0;Initial version'
      data << '2;1.1.0;Minor change'
      versions = SolrDocument.new('versions_ssm' => data).get_versions
      expect(versions['1']).to match a_hash_including(tag: '1.0.0', desc: 'Initial version')
      expect(versions['2']).to match a_hash_including(tag: '1.1.0', desc: 'Minor change')
    end
  end
end
