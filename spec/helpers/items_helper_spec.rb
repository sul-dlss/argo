# encoding: utf-8
require 'spec_helper'
describe ItemsHelper, :type => :helper do
  let(:mods_xml) do
    '<mods:mods
        xmlns:mods="http://www.loc.gov/mods/v3">
        <mods:identifier type="local" displayLabel="SU DRUID">druid:sm817db3005</mods:identifier>
        <mods:titleInfo type="main">
            <mods:title>A New and Curious Map of the World
        </mods:titleInfo>
        <mods:typeOfResource>cartographic</mods:typeOfResource>
        <mods:originInfo>
            <mods:place>
                <mods:placeTerm type="text"/>
            </mods:place>
            <mods:dateCreated encoding="w3cdtf" keyDate="yes" qualifier="questionable">1700</mods:dateCreated>
        </mods:originInfo>
        <mods:name type="personal" authority="local">
            <mods:namePart type=""/>
            <mods:role>
                <mods:roleTerm type="text" authority="marcrelator"/>
            </mods:role>
        </mods:name>
        <mods:physicalDescription>
            <mods:form authority="marcform"/>
            <mods:internetMediaType>image/tiff</mods:internetMediaType>
            <mods:extent/>
            <mods:digitalOrigin>digitized other analog</mods:digitalOrigin>
        </mods:physicalDescription>
        <mods:location>
            <mods:physicalLocation/>
            <mods:url usage="primary display" access=""/>
        </mods:location>
        <mods:genre>Digital Maps</mods:genre>
    </mods:mods>'
  end
  context 'schema_validate' do
    it 'should validate a document' do
      doc = Nokogiri.XML(mods_xml) do |config|
        config.default_xml.noblanks
      end
      # the expected length is the number of error statements from validation
      # here's what the array looks like:
      # ["Element '{http://www.loc.gov/mods/v3}titleInfo', attribute 'type': [facet 'enumeration'] The value 'main' is not an element of the set {'abbreviated', 'translated', 'alternative', 'uniform'}.",
      # "Element '{http://www.loc.gov/mods/v3}titleInfo', attribute 'type': 'main' is not a valid value of the atomic type '{http://www.loc.gov/mods/v3}titleInfoTypeAttributeDefinition'.",
      # "Element '{http://www.loc.gov/mods/v3}typeOfResource': This element is not expected."]
      expect(schema_validate(doc).length).to eq(3)
    end
  end
end
