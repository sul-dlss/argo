# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DublinCoreService do
  subject(:service) { described_class.new(desc_md_xml) }

  let(:cocina_object) do
    build(:dro, id: 'druid:bc123df4567').new(description:)
  end
  let(:desc_md_xml) { ModsService.new(cocina_object).ng_xml(include_access_conditions: false) }
  let(:solr_client) { instance_double(RSolr::Client, get: solr_response) }
  let(:solr_response) { { 'response' => { 'docs' => virtual_object_solr_docs } } }
  let(:virtual_object_solr_docs) { [] }

  before do
    allow(Mods::SolrService.instance).to receive(:conn).and_return(solr_client)
  end

  describe '#ng_xml' do
    subject(:xml) { service.ng_xml }

    let(:description) do
      {
        title: [{ value: 'Slides, IA, Geodesic Domes [1 of 2]' }],
        purl: 'https://purl.stanford.edu/bc123df4567',
        form: [
          { value: 'still image', type: 'resource type', source: { value: 'MODS resource types' } },
          { value: 'photographs, color transparencies', type: 'form' }
        ],
        identifier: [
          { displayLabel: 'Image ID', type: 'local', value: 'M1090_S15_B01_F01_0055' }
        ],
        relatedResource: [
          { title: [{ value: 'Buckminster Fuller papers, 1920-1983' }],
            form: [{ value: 'collection', source: { value: 'MODS resource types' } }], type: 'part of' },
          { access: { physicalLocation: [{ value: 'Series 15 | Box 1 | Folder 1', type: 'location' }] },
            type: 'part of' }
        ],
        access: { accessContact: [{ value: 'Stanford University. Libraries. Dept. of Special Collections and Stanford University Archives.', type: 'repository' }],
                  note: [{ value: 'Property rights reside with the repository. ' \
                                  'Intellectual rights to the images reside with the creators of the images or their heirs. ' \
                                  'To obtain permission to publish or reproduce, please contact the Public Services Librarian of the Dept. of Special Collections.' }] }
      }
    end

    it 'produces dublin core Stanford-specific mapping for repository, collection and location' do
      expect(xml).to be_equivalent_to read_fixture('ex2_related_dc.xml')
    end
  end
end
