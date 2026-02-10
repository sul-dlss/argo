# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DescriptionImport do
  subject(:updated) { described_class.import(csv_row: csv.first) }

  context 'with a valid csv' do
    let(:csv) do
      # From https://argo-stage.stanford.edu/view/druid:bb041bm1345
      CSV.read(file_fixture('descriptive-upload.csv'), headers: true)
    end
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
              "structuredValue": [{#{"\t\t\t\t\t\t"}
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
          "event": [{#{"\t\t\t\t"}
            "location": [{#{"\t\t\t\t\t"}
              "code": "xx",
              "source": {
                "code": "marccountry"
              }
            }],#{"\t\t\t\t"}
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
            }]#{"\t\t\t\t"}
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

    it 'deserializes the item' do
      expect(updated.value!).to eq expected
    end

    context 'with columns out of order' do
      let(:csv) do
        # Reverse the columns
        table = CSV.read(file_fixture('descriptive-upload.csv'), headers: true)
        new_headers = table.headers.reverse
        CSV::Table.new([], headers: new_headers).tap do |new_table|
          new_table << new_headers.map { |header| table.first[header] }
        end
      end

      it 'deserializes the item' do
        expect(updated.value!).to eq expected
      end
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

  context 'when top level contributor' do
    let(:csv) do
      CSV.parse(csv_data, headers: true)
    end
    let(:expected_hash) do
      {
        title: [{ value: 'my great contributor' }],
        purl: 'https://purl/jr825qh8124'
      }.tap do |h|
        h[:contributor] = [expected_contributor] if expected_contributor
      end
    end
    let(:expected) { Cocina::Models::Description.new(expected_hash) }

    [nil, 'Someone'].each do |name|
      context "when role as code (not value), name: '#{name}'" do
        let(:csv_data) do
          <<~CSV
            druid,source_id,purl,title1.value,contributor1.name1.value,contributor1.role1.code,contributor1.role1.value
            jr825qh8124,event:contrib-roles,https://purl/jr825qh8124,my great contributor,#{name},pbl,
          CSV
        end
        let(:expected_contributor) do
          if name
            {
              name: [{ value: name }],
              role: [{ code: 'pbl' }]
            }
          end
        end

        it 'has the expected value' do
          expect(updated.value!.to_h).to eq expected.to_h
        end
      end

      context "when role as value (not code), name: '#{name}'" do
        let(:csv_data) do
          <<~CSV
            druid,source_id,purl,title1.value,contributor1.name1.value,contributor1.role1.code,contributor1.role1.value
            jr825qh8124,event:contrib-roles,https://purl/jr825qh8124,my great contributor,#{name},,Publisher
          CSV
        end
        let(:expected_contributor) do
          if name
            {
              name: [{ value: name }],
              role: [{ value: 'Publisher' }]
            }
          end
        end

        it 'has the expected value' do
          expect(updated.value!.to_h).to eq expected.to_h
        end
      end

      context "when role as both code and value, name: '#{name}'" do
        let(:csv_data) do
          <<~CSV
            druid,source_id,purl,title1.value,contributor1.name1.value,contributor1.role1.code,contributor1.role1.value
            jr825qh8124,event:contrib-roles,https://purl/jr825qh8124,my great contributor,#{name},pbl,Publisher
          CSV
        end
        let(:expected_contributor) do
          if name
            {
              name: [{ value: name }],
              role: [
                {
                  code: 'pbl',
                  value: 'Publisher'
                }
              ]
            }
          end
        end

        it 'has the expected value' do
          expect(updated.value!.to_h).to eq expected.to_h
        end
      end

      context "when role code and value both empty, name: '#{name}'" do
        let(:csv_data) do
          <<~CSV
            druid,source_id,purl,title1.value,contributor1.name1.value,contributor1.role1.code,contributor1.role1.value
            jr825qh8124,event:contrib-roles,https://purl/jr825qh8124,my great contributor,#{name},,
          CSV
        end
        let(:expected_contributor) do
          if name
            {
              name: [{ value: name }]
            }
          end
        end

        it 'has the expected value' do
          expect(updated.value!.to_h).to eq expected.to_h
        end
      end
    end
  end

  context 'with a contributor within an event' do
    subject(:contributors) { updated.value!.event.first.contributor }

    let(:csv) do
      CSV.parse(csv_data, headers: true)
    end

    let(:expected) { Cocina::Models::Description.new(expected_hash) }

    context 'when name, identifier, and valueAt are missing but role is present' do
      let(:csv_data) do
        <<~CSV
          druid,source_id,purl,title1.value,event1.contributor1.name1.value,event1.contributor1.role1.code,event1.contributor1.role1.value,event1.note1.value
          jr825qh8124,event:contrib-roles,https://purl/jr825qh8124,my great event,,pbl,Publisher,noted
        CSV
      end

      it 'has the expected value' do
        expect(contributors).to be_empty
      end
    end

    context 'when name value is present ("Someone")' do
      context 'when role as code (not value)' do
        let(:csv_data) do
          <<~CSV
            druid,source_id,purl,title1.value,event1.contributor1.name1.value,event1.contributor1.role1.code,event1.contributor1.role1.value,event1.note1.value
            jr825qh8124,event:contrib-roles,https://purl/jr825qh8124,my great event,Someone,pbl,,noted
          CSV
        end

        it 'has the expected value' do
          expect(contributors).to eq [Cocina::Models::Contributor.new(
            name: [{ value: 'Someone' }],
            role: [{ code: 'pbl' }]
          )]
        end
      end

      context 'when role as value (not code)' do
        let(:csv_data) do
          <<~CSV
            druid,source_id,purl,title1.value,event1.contributor1.name1.value,event1.contributor1.role1.code,event1.contributor1.role1.value,event1.note1.value
            jr825qh8124,event:contrib-roles,https://purl/jr825qh8124,my great event,Someone,,Publisher,noted
          CSV
        end

        it 'has the expected value' do
          expect(contributors).to eq [Cocina::Models::Contributor.new(
            name: [{ value: 'Someone' }],
            role: [{ value: 'Publisher' }]
          )]
        end
      end

      context 'when role as both code and value' do
        let(:csv_data) do
          <<~CSV
            druid,source_id,purl,title1.value,event1.contributor1.name1.value,event1.contributor1.role1.code,event1.contributor1.role1.value,event1.note1.value
            jr825qh8124,event:contrib-roles,https://purl/jr825qh8124,my great event,Someone,pbl,Publisher,noted
          CSV
        end

        it 'has the expected value' do
          expect(contributors).to eq [Cocina::Models::Contributor.new(
            name: [{ value: 'Someone' }],
            role: [
              {
                code: 'pbl',
                value: 'Publisher'
              }
            ]
          )]
        end
      end

      context 'when role code and value both empty' do
        let(:csv_data) do
          <<~CSV
            druid,source_id,purl,title1.value,event1.contributor1.name1.value,event1.contributor1.role1.code,event1.contributor1.role1.value,event1.note1.value
            jr825qh8124,event:contrib-roles,https://purl/jr825qh8124,my great event,Someone,,,noted
          CSV
        end

        it 'has the expected value' do
          expect(contributors).to eq [Cocina::Models::Contributor.new(name: [{ value: 'Someone' }])]
        end
      end
    end

    context 'when identifier is present' do
      let(:csv_data) do
        <<~CSV
          druid,source_id,purl,title1.value,event1.contributor1.identifier1.value,event1.contributor1.role1.code,event1.contributor1.role1.value,event1.note1.value
          jr825qh8124,event:contrib-roles,https://purl/jr825qh8124,my great event,0000-0003-0698-1930,pbl,,noted
        CSV
      end

      it 'has the expected value' do
        expect(contributors).to eq [Cocina::Models::Contributor.new(
          identifier: [{ value: '0000-0003-0698-1930' }],
          role: [{ code: 'pbl' }]
        )]
      end
    end

    context 'when valueAt is present' do
      let(:csv_data) do
        <<~CSV
          druid,source_id,purl,title1.value,event1.contributor1.valueAt,event1.contributor1.role1.code,event1.contributor1.role1.value,event1.note1.value
          jr825qh8124,event:contrib-roles,https://purl/jr825qh8124,my great event,http://example.com/,pbl,,noted
        CSV
      end

      it 'has the expected value' do
        expect(contributors).to eq [Cocina::Models::Contributor.new(
          valueAt: 'http://example.com/',
          role: [{ code: 'pbl' }]
        )]
      end
    end
  end

  context 'with form property' do
    let(:title) { 'my great form' }
    let(:csv) do
      CSV.parse(csv_data, headers: true)
    end
    let(:expected) { Cocina::Models::Description.new(expected_hash) }

    context 'when at top level' do
      let(:expected_hash) do
        {
          title: [{ value: title }],
          purl: 'https://purl/jr825qh8124'
        }.tap do |h|
          h[:form] = [expected_form] if expected_form
        end
      end

      [nil, 'prints'].each do |form_value|
        context "when type, no source, value: '#{form_value}'" do
          let(:csv_data) do
            <<~CSV
              druid,source_id,purl,title1.value,form1.value,form1.type,form1.source.code,form1.source.value,form1.source.uri
              jr825qh8124,form:values,https://purl/jr825qh8124,#{title},#{form_value},genre,,,
            CSV
          end
          let(:expected_form) do
            if form_value
              {
                value: form_value,
                type: 'genre'
              }
            end
          end

          it 'has the expected value' do
            expect(updated.value!.to_h).to eq expected.to_h
          end
        end

        context "when form source as code (not value or URI), no form type, form value: '#{form_value}'" do
          let(:csv_data) do
            <<~CSV
              druid,source_id,purl,title1.value,form1.value,form1.type,form1.source.code,form1.source.value,form1.source.uri
              jr825qh8124,form:values,https://purl/jr825qh8124,#{title},#{form_value},,lcgft,,
            CSV
          end
          let(:expected_form) do
            if form_value
              {
                value: form_value,
                source: { code: 'lcgft' }
              }
            end
          end

          it 'has the expected value' do
            expect(updated.value!.to_h).to eq expected.to_h
          end
        end

        context "when form source as value (not code or URI), no form type, form value: '#{form_value}'" do
          let(:csv_data) do
            <<~CSV
              druid,source_id,purl,title1.value,form1.value,form1.type,form1.source.code,form1.source.value,form1.source.uri
              jr825qh8124,form:values,https://purl/jr825qh8124,#{title},#{form_value},,,source-value,
            CSV
          end
          let(:expected_form) do
            if form_value
              {
                value: form_value,
                source: { value: 'source-value' }
              }
            end
          end

          it 'has the expected value' do
            expect(updated.value!.to_h).to eq expected.to_h
          end
        end

        context "when form source as URI (not code or value), no form type, form value: '#{form_value}'" do
          let(:csv_data) do
            <<~CSV
              druid,source_id,purl,title1.value,form1.value,form1.type,form1.source.code,form1.source.value,form1.source.uri
              jr825qh8124,form:values,https://purl/jr825qh8124,#{title},#{form_value},,,,http://id.loc.gov/authorities/genreForms/
            CSV
          end
          let(:expected_form) do
            if form_value
              {
                value: form_value,
                source: { uri: 'http://id.loc.gov/authorities/genreForms/' }
              }
            end
          end

          it 'has the expected value' do
            expect(updated.value!.to_h).to eq expected.to_h
          end
        end

        context "when form source as code and URI (no value), no form type, form value: '#{form_value}'" do
          let(:csv_data) do
            <<~CSV
              druid,source_id,purl,title1.value,form1.value,form1.type,form1.source.code,form1.source.value,form1.source.uri
              jr825qh8124,form:values,https://purl/jr825qh8124,#{title},#{form_value},,lcgft,,http://id.loc.gov/authorities/genreForms/
            CSV
          end
          let(:expected_form) do
            if form_value
              {
                value: form_value,
                source: {
                  code: 'lcgft',
                  uri: 'http://id.loc.gov/authorities/genreForms/'
                }
              }
            end
          end

          it 'has the expected value' do
            expect(updated.value!.to_h).to eq expected.to_h
          end
        end

        context "when form source and type empty, form value: '#{form_value}'" do
          let(:csv_data) do
            <<~CSV
              druid,source_id,purl,title1.value,form1.value,form1.type,form1.source.code,form1.source.value,form1.source.uri
              jr825qh8124,form:values,https://purl/jr825qh8124,#{title},#{form_value},,,,
            CSV
          end
          let(:expected_form) do
            { value: form_value } if form_value
          end

          it 'has the expected value' do
            expect(updated.value!.to_h).to eq expected.to_h
          end
        end
      end

      context 'when form.structuredValue present' do
        let(:csv_data) do
          <<~CSV
            druid,source_id,purl,title1.value,form1.source.value,form1.structuredValue1.type,form1.structuredValue1.value,form1.structuredValue2.type,form1.structuredValue2.value,form1.type
            jr825qh8124,form:values,https://purl/jr825qh8124,#{title},Stanford self-deposit resource types,type,Text,subtype,Article,resource type
          CSV
        end
        let(:expected_form) do
          {
            structuredValue: [
              {
                value: 'Text',
                type: 'type'
              },
              {
                value: 'Article',
                type: 'subtype'
              }
            ],
            type: 'resource type',
            source: {
              value: 'Stanford self-deposit resource types'
            }
          }
        end

        it 'has the expected value' do
          expect(updated.value!.to_h).to eq expected.to_h
        end
      end
    end

    context 'when at nested level' do
      let(:expected_hash) do
        {
          title: [{ value: title }],
          purl: 'https://purl/jr825qh8124'
        }.tap do |h|
          form_value =
            if expected_form
              [expected_form]
            else
              []
            end
          h[:relatedResource] = [
            form: form_value,
            title: [],
            contributor: [],
            event: [],
            language: [],
            note: [],
            identifier: [],
            subject: []
          ]
        end
      end
      let(:expected) { Cocina::Models::Description.new(expected_hash) }

      [nil, 'prints'].each do |form_value|
        context "when form has type, no source, value: '#{form_value}'" do
          let(:csv_data) do
            <<~CSV
              druid,source_id,purl,title1.value,relatedResource1.form1.value,relatedResource1.form1.type,relatedResource1.form1.source.code,relatedResource1.form1.source.value,relatedResource1.form1.source.uri
              jr825qh8124,form:values,https://purl/jr825qh8124,#{title},#{form_value},genre,,,
            CSV
          end
          let(:expected_form) do
            if form_value
              {
                value: form_value,
                type: 'genre'
              }
            end
          end

          it 'has the expected value' do
            expect(updated.value!.to_h).to eq expected.to_h
          end
        end
      end
    end
  end

  context 'with language property' do
    let(:csv) do
      CSV.parse(csv_data, headers: true)
    end

    context 'when language has a value' do
      let(:csv_data) do
        <<~CSV
          druid,source_id,title1.value,purl,language1.value,language1.code,language1.uri,language1.displayLabel
          druid:bc123df4567,desc:no-title-type,A title,https://purl/bc123df4567,English,en,https://id.loc.gov/vocabulary/iso639-2/eng,English
        CSV
      end

      it 'deserializes the item' do
        expect(updated.value!.language.as_json).to eq [{ 'appliesTo' => [],
                                                         'code' => 'en',
                                                         'displayLabel' => 'English',
                                                         'groupedValue' => [],
                                                         'note' => [],
                                                         'parallelValue' => [],
                                                         'structuredValue' => [],
                                                         'uri' => 'https://id.loc.gov/vocabulary/iso639-2/eng',
                                                         'value' => 'English' }]
      end
    end

    context 'when language has no value' do
      let(:csv_data) do
        <<~CSV
          druid,source_id,title1.value,purl,language1.value,language1.code,language1.uri,language1.displayLabel
          druid:bc123df4567,desc:no-title-type,A title,https://purl/bc123df4567,,,,Should not be accepted
        CSV
      end

      it 'rejects the item' do
        expect(updated.value!.language).to be_empty
      end
    end

    context 'when language has a note' do
      let(:csv_data) do
        <<~CSV
          druid,source_id,title1.value,purl,language1.value,language1.code,language1.uri,language1.note1.value
          druid:bc123df4567,desc:no-title-type,A title,https://purl/bc123df4567,,,,A language note
        CSV
      end

      it 'deserializes the item' do
        expect(updated.value!.language.as_json).to eq [
          { 'appliesTo' => [],
            'groupedValue' => [],
            'note' => [{ 'structuredValue' => [], 'parallelValue' => [], 'groupedValue' => [], 'value' => 'A language note',
                         'identifier' => [], 'note' => [], 'appliesTo' => [] }],
            'parallelValue' => [],
            'structuredValue' => [] }
        ]
      end
    end
  end

  context 'with event date property' do
    let(:csv) do
      CSV.parse(csv_data, headers: true)
    end

    context 'when event date has a value' do
      let(:csv_data) do
        <<~CSV
          druid,source_id,title1.value,purl,event1.date1.value,event1.date1.type
          druid:bc123df4567,desc:no-title-type,A title,https://purl/bc123df4567,2022-01-01,creation
        CSV
      end

      it 'deserializes the item' do
        expect(updated.value!.event.first.date).to eq [
          Cocina::Models::DescriptiveValue.new(type: 'creation', value: '2022-01-01')
        ]
      end
    end

    context 'when event date has no value' do
      let(:csv_data) do
        <<~CSV
          druid,source_id,title1.value,purl,event1.date1.value,event1.date1.type
          druid:bc123df4567,desc:no-title-type,A title,https://purl/bc123df4567,,creation
        CSV
      end

      it 'rejects the item' do
        expect(updated.value!.event.first.date).to be_empty
      end
    end

    context 'when event date has a note' do
      let(:csv_data) do
        <<~CSV
          druid,source_id,title1.value,purl,event1.date1.value,event1.date1.type,event1.date1.note1.value
          druid:bc123df4567,desc:no-title-type,A title,https://purl/bc123df4567,,creation,A date note
        CSV
      end

      it 'deserializes the item' do
        expect(updated.value!.event.first.date).to eq [
          Cocina::Models::DescriptiveValue.new(type: 'creation', note: [{ value: 'A date note' }])
        ]
      end
    end
  end
end
