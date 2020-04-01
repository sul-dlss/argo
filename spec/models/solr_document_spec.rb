# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrDocument, type: :model do
  describe '#milestones' do
    it 'builds an empty listing if passed an empty doc' do
      milestones = described_class.new({}).milestones
      milestones.each do |key, value|
        expect(value).to match a_hash_excluding(:time)
      end
    end

    it 'generates a correct lifecycle with the old format that lacks version info' do
      doc = described_class.new('lifecycle_ssim' => ['registered:2012-02-25T01:40:57Z'])

      versions = doc.milestones
      expect(versions.keys).to eq [1]
      expect(versions).to match a_hash_including(
        1 => a_hash_including(
          'registered' => { time: be_a_kind_of(DateTime) }
        )
      )
      versions[1].each do |key, value|
        if key == 'registered'
          expect(value[:time].to_s(:iso8601)).to eq('2012-02-25T01:40:57+00:00')
        else
          expect(value[:time]).to be_nil
        end
      end
    end

    it 'recognizes versions and bundle versions together' do
      lifecycle_data = ['registered:2012-02-25T01:40:57Z;1', 'opened:2012-02-25T01:39:57Z;2']
      versions = described_class.new('lifecycle_ssim' => lifecycle_data).milestones
      expect(versions['1'].size).to eq(6)
      expect(versions['2'].size).to eq(6)
      expect(versions['1']['registered']).not_to be_nil
      expect(versions['2']['registered']).to be_nil
      expect(versions['2']['opened']).not_to be_nil
      expect(versions).to match a_hash_including(
        '1' => a_hash_including(
          'registered' => {
            time: be_a_kind_of(DateTime)
          }
        ),
        '2' => a_hash_including(
          'opened' => {
            time: be_a_kind_of(DateTime)
          }
        )
      )
      versions.each do |version, milestones|
        milestones.each do |key, value|
          case key
          when 'registered'
            expect(value[:time]).to be_a_kind_of DateTime
            expect(value[:time].to_s(:iso8601)).to eq('2012-02-25T01:40:57+00:00')
            expect(version).to eq('1') # registration is always only on v1
          when 'opened'
            expect(value[:time]).to be_a_kind_of DateTime
            expect(value[:time].to_s(:iso8601)).to eq('2012-02-25T01:39:57+00:00')
            expect(version).to eq('2')
          else
            expect(value[:time]).to be_nil
          end
        end
      end
    end
  end

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
      versions = described_class.new('versions_ssm' => data).get_versions
      expect(versions['1']).to match a_hash_including(tag: '1.0.0', desc: 'Initial version')
      expect(versions['2']).to match a_hash_including(tag: '1.1.0', desc: 'Minor change')
    end
  end
end
