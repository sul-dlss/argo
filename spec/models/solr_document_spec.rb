# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrDocument, type: :model do
  let(:document) { described_class.new(document_attributes) }

  describe '#object_type' do
    context 'when field present' do
      let(:document_attributes) do
        { SolrDocument::FIELD_OBJECT_TYPE => ['item', 'other stuff'] }
      end

      it 'returns the first object type' do
        expect(document.object_type).to eq 'item'
      end
    end

    context 'when field not present' do
      let(:document_attributes) { {} }

      it 'returns nil' do
        expect(document.object_type).to be_nil
      end
    end
  end

  describe '#admin_policy?' do
    context 'when object type is an adminPolicy' do
      let(:document_attributes) do
        { SolrDocument::FIELD_OBJECT_TYPE => ['adminPolicy'] }
      end

      it 'checks and returns true' do
        expect(document.admin_policy?).to be true
      end
    end

    context 'when object type is not an adminPolicy' do
      let(:document_attributes) do
        { SolrDocument::FIELD_OBJECT_TYPE => ['item'] }
      end

      it 'checks and returns false' do
        expect(document.admin_policy?).to be false
      end
    end

    context 'when object type is missing' do
      let(:document_attributes) { {} }

      it 'checks and returns false' do
        expect(document.admin_policy?).to be false
      end
    end
  end

  describe '#datastreams' do
    subject(:datastreams) { document.datastreams }

    let(:document_attributes) do
      { 'ds_specs_ssim' => [
        'DC|X|text/xml|0|475|Dublin Core Record for this object',
        'RELS-EXT|X|application/rdf+xml|0|821|Fedora Object-to-Object Relationship Metadata',
        'identityMetadata|M|text/xml|0|635|Identity Metadata',
        'rightsMetadata|M|text/xml|4|652|Rights metadata',
        'descMetadata|M|text/xml|3|5988|Descriptive Metadata',
        'workflows|E|application/xml|0|10780|Workflows'
      ] }
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

  describe '#versions' do
    subject(:versions) { document.versions }

    let(:data) { ['1;1.0.0;Initial version', '2;1.1.0;Minor change'] }
    let(:document) { described_class.new('versions_ssm' => data) }

    it 'is a list of versions' do
      expect(versions).to eq data
    end
  end

  context 'when it is embargoed' do
    let(:document_attributes) do
      {
        SolrDocument::FIELD_EMBARGO_STATUS => ['embargoed'],
        SolrDocument::FIELD_EMBARGO_RELEASE_DATE => ['24/02/2259']
      }
    end

    it 'returns embargo status' do
      expect(document).to be_embargoed
      expect(document.embargo_status).to eq 'embargoed'
      expect(document.embargo_release_date).to eq '24/02/2259'
    end
  end

  context 'when it is not embargoed' do
    let(:document_attributes) { {} }

    context 'with no field' do
      it 'returns nil' do
        expect(document).not_to be_embargoed
        expect(document.embargo_status).to be_nil
        expect(document.embargo_release_date).to be_nil
      end
    end

    context 'with empty field' do
      let(:document_attributes) do
        {
          SolrDocument::FIELD_EMBARGO_STATUS => nil,
          SolrDocument::FIELD_EMBARGO_RELEASE_DATE => nil
        }
      end

      it 'returns nil' do
        expect(document).not_to be_embargoed
        expect(document.embargo_status).to be_nil
        expect(document.embargo_release_date).to be_nil
      end
    end
  end

  describe '#catkey' do
    context 'when catkey is not present' do
      let(:document_attributes) { {} }

      it 'returns nil' do
        expect(document.catkey).to be_nil
        expect(document.catkey_id).to be_nil
      end
    end

    context 'when a catkey is present' do
      let(:document_attributes) { { SolrDocument::FIELD_CATKEY_ID => ['catkey:8675309'] } }

      it 'returns catkey value' do
        expect(document.catkey).to eq 'catkey:8675309'
        expect(document.catkey_id).to eq '8675309'
      end
    end
  end
end
