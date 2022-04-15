# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DescriptionImport do
  subject(:updated) { described_class.import(csv_row: csv.first) }

  let(:expected_json) do
    <<~JSON
      {
      	"title": [{
      		"value": "Concerto for piano, strings, brass and percussion!",
      		"status": "primary"
      	}, {
      		"value": "Concertos, piano, orchestra",
      		"type": "uniform",
      		"note": [{
      			"structuredValue": [{
      				"value": "Harvey, Robert Gibson",
      				"type": "name"
      			}, {
      				"value": "1951-",
      				"type": "life dates"
      			}],
      			"type": "associated name"
      		}]
      	}],
      	"contributor": [{
      		"name": [{
      			"structuredValue": [{#{'						'}
      				"value": "Harvey, Robert Gibson",
      				"type": "name"
      			}, {
      				"value": "1951-",
      				"type": "life dates"
      			}]
      		}],
      		"type": "person",
      		"status": "primary"
      	}],
      	"event": [{#{'				'}
      		"location": [{#{'					'}
      			"code": "xx",
      			"source": {
      				"code": "marccountry"
      			}
      		}],#{'				'}
      		"note": [{
      			"value": "monographic",
      			"type": "issuance",
      			"source": {
      				"value": "MODS issuance terms"
      			}
      		}]
      	}, {
      		"date": [{
      			"value": "1978",
      			"type": "publication"
      		}]
      	}],
      	"form": [{
      		"value": "notated music",
      		"type": "resource type",
      		"source": {
      			"value": "MODS resource types"
      		}
      	}, {
      		"value": "print",
      		"type": "form",
      		"source": {
      			"code": "marcform"
      		}
      	}, {
      		"value": "score (77 leaves) : music ; 28 cm.",
      		"type": "extent"
      	}],
      	"language": [{
      		"code": "und",
      		"source": {
      			"code": "iso639-2b"
      		}
      	}],
      	"note": [{
      		"value": "by Robert Harvey.",
      		"type": "statement of responsibility"
      	}, {
      		"value": "D.M.A. project - Department of Music, Stanford University.",
      		"type": "thesis"
      	}],
      	"subject": [{
      		"structuredValue": [{
      			"value": "Concertos (Piano)",
      			"type": "topic"
      		}, {
      			"value": "Scores",
      			"type": "genre"
      		}],
      		"source": {
      			"code": "lcsh"
      		}
      	}],
      	"relatedResource": [{
      		"title": [{
      			"structuredValue": [{
      				"value": "Projects",
      				"type": "main title"
      			}, {
      				"value": "D.M.A. Final",
      				"type": "part name"
      			}]
      		}],
      		"contributor": [{
      			"name": [{
      				"structuredValue": [{
      					"value": "Stanford University",
      					"type": "name"
      				}, {
      					"value": "Department of Music",
      					"type": "name"
      				}]
      			}],
      			"type": "organization"
      		}]#{'				'}
      	}],
      	"adminMetadata": {
      		"contributor": [{
      			"name": [{
      				"code": "CSt",
      				"source": {
      					"code": "marcorg"
      				}
      			}],
      			"type": "organization",
      			"role": [{
      				"value": "original cataloging agency"
      			}]
      		}],
      		"event": [{
      			"type": "creation",
      			"date": [{
      				"value": "790730",
      				"encoding": {
      					"code": "marc"
      				}
      			}]
      		}, {
      			"type": "modification",
      			"date": [{
      				"value": "19900820141050.0",
      				"encoding": {
      					"code": "iso8601"
      				}
      			}]
      		}],
      		"note": [{
      			"value": "Converted from MARCXML to MODS version 3.7 using MARC21slim2MODS3-7_SDR_v2-5.xsl (SUL 3.7 version 2.5 20210421; LC Revision 1.140 20200717)",
      			"type": "record origin"
      		}],
      		"identifier": [{
      			"value": "a111",
      			"type": "SIRSI"
      		}]
      	},
      	"purl": "https://sul-purl-stage.stanford.edu/bb041bm1345"
      }
    JSON
  end

  let(:expected) { Cocina::Models::Description.new(JSON.parse(expected_json)) }

  context 'with a valid csv' do
    let(:csv) do
      # From https://argo-stage.stanford.edu/view/druid:bb041bm1345
      CSV.read(file_fixture('descriptive-upload.csv'), headers: true)
    end

    it 'deserializes the item' do
      expect(updated.value!).to eq expected
    end
  end

  context 'with an invalid csv' do
    let(:csv) do
      CSV.read(file_fixture('bulk_upload_structural.csv'), headers: true)
    end

    it 'returns an error' do
      expect(updated).to be_failure
    end
  end

  context 'with a csv that has nil values' do
    # This case occurs when you do a bulk export of a dense and a sparse object on the same sheet
    let(:csv) do
      CSV.parse("access:accessContact1:source:code,title1:value,purl\n,my title,https://purl\n", headers: true)
    end

    let(:expected) do
      Cocina::Models::Description.new(title: [{ value: 'my title' }], purl: 'https://purl')
    end

    it 'ignores the empty field' do
      expect(updated.value!).to eq expected
    end
  end

  context 'with a csv that has varied nested values' do
    # This case occurs when you do a bulk import of different object structures
    let(:csv_data) do
      <<~CSV
        druid,source_id,purl,title1.value,contributor3.name3.parallelValue3.structuredValue1.value,contributor3.name3.parallelValue3.structuredValue1.type,contributor3.name3.parallelValue3.structuredValue2.value,contributor3.name3.parallelValue3.structuredValue2.type,contributor3.name3.parallelValue4.structuredValue1.value,contributor3.name3.parallelValue4.structuredValue1.type,contributor3.name3.parallelValue4.structuredValue2.value,contributor3.name3.parallelValue4.structuredValue2.type
        jr825qh8124,foo2:bar2,https://purl/jr825qh8124,Title 2,Parallel 1 part 1,name,1800-1900,life dates,Parallel 2 part 1,name,marchioness,term of address
      CSV
    end
    let(:csv) do
      CSV.parse(csv_data, headers: true)
    end

    let(:expected) do
      Cocina::Models::Description.new(
        title: [{ value: 'Title 2' }],
        purl: 'https://purl/jr825qh8124',
        contributor: [
          { name: [
            { parallelValue: [
              { structuredValue: [
                { value: 'Parallel 1 part 1', type: 'name' },
                { value: '1800-1900', type: 'life dates' }
              ] },
              { structuredValue: [
                { value: 'Parallel 2 part 1', type: 'name' },
                { value: 'marchioness', type: 'term of address' }
              ] }
            ] }
          ] }
        ]
      )
    end

    it 'ignores the empty field' do
      expect(updated.value!).to eq expected
    end
  end
end
