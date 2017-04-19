# encoding: utf-8
require 'spec_helper'
describe ItemsHelper, :type => :helper do
  before :each do
    @full_doc = '  <mods:mods xmlns:xxi="http://orbeon.org/oxf/xml/xinclude" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xbl="http://www.w3.org/ns/xbl" xmlns:exforms="http://www.exforms.org/exf/1-0" xmlns:pipeline="java:org.orbeon.oxf.processor.pipeline.PipelineFunctionLibrary" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:fr="http://orbeon.org/oxf/xml/form-runner" xmlns:dl="http://dl.lib.brown.edu/editor/mods/dl" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xxforms="http://orbeon.org/oxf/xml/xforms">
    <mods:identifier type="local" displayLabel="SU DRUID">druid:sm817db3005</mods:identifier>
    <mods:identifier type="local" displayLabel="Post publication map number">1143</mods:identifier>
    <mods:titleInfo type="main">
    <mods:nonSort/>
    <mods:title>A New and Curious Map of the World
    </mods:title>
    <mods:subTitle/>
    <mods:partNumber/>
    <mods:partName/>
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
    <mods:genre/>
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
    <mods:subject authority="keyword">
    <mods:topic/>
    </mods:subject>
    <mods:recordInfo>
    <mods:recordContentSource>Lyberteam Metadata ToolKit</mods:recordContentSource>
    <mods:recordCreationDate encoding="iso8601"/>
    </mods:recordInfo>
    <mods:accessCondition displayLabel="Copyright Stanford University. Stanford, CA 94305. (650) 723-2300." type="useAndReproduction">
    Stanford University Libraries and Academic Information Resources - Terms of
    Use SULAIR Web sites are subject to Stanford University&apos;s standard Terms of
    Use (See http://www.stanford.edu/home/atoz/terms.html) These terms include a
    limited personal, non-exclusive, non-transferable license to access and use
    the sites, and to download - where permitted - material for personal,
    non-commercial, non-display use only. Please contact the University
    Librarian to request permission to use SULAIR Web sites and contents beyond
    the scope of the above license, including but not limited to republication
    to a group or republishing the Web site or parts of the Web site. SULAIR
    provides access to a variety of external databases and resources, which
    sites are governed by their own Terms of Use, as well as contractual access
    restrictions. The Terms of Use on these external sites always govern the
    data available there. Please consult with library staff if you have
    questions about data access and availability.
    </mods:accessCondition>
    <mods:genre>Early Maps</mods:genre>
    <mods:genre>Digital Maps</mods:genre>
    <mods:relatedItem type="host">
    <mods:titleInfo>
    <mods:nonSort>The</mods:nonSort>
    <mods:title>mapping of California as an island</mods:title>
    <mods:subTitle>an illustrated checklist</mods:subTitle>
    </mods:titleInfo>
    <mods:titleInfo type="alternative">
    <mods:title>California as an island</mods:title>
    </mods:titleInfo>
    <mods:name type="personal">
    <mods:namePart>McLaughlin, Glen</mods:namePart>
    <mods:namePart type="date">1934-</mods:namePart>
    <mods:role>
    <mods:roleTerm authority="marcrelator" type="text">creator</mods:roleTerm>
    </mods:role>
    </mods:name>
    <mods:name type="personal">
    <mods:namePart>Mayo, Nancy H.</mods:namePart>
    </mods:name>
    <mods:name type="corporate">
    <mods:namePart>California Map Society</mods:namePart>
    </mods:name>
    <mods:typeOfResource>text</mods:typeOfResource>
    <mods:genre authority="marcgt">bibliography</mods:genre>
    <mods:originInfo>
    <mods:place>
    <mods:placeTerm type="code" authority="marccountry">cau</mods:placeTerm>
    </mods:place>
    <mods:place>
    <mods:placeTerm type="text">[Saratoga, CA]</mods:placeTerm>
    </mods:place>
    <mods:publisher>California Map Society</mods:publisher>
    <mods:dateIssued>c1995</mods:dateIssued>
    <mods:dateIssued encoding="marc" keyDate="yes">1995</mods:dateIssued>
    <mods:edition>1st ed.</mods:edition>
    <mods:issuance>monographic</mods:issuance>
    </mods:originInfo>
    <mods:physicalDescription>
    <mods:form authority="marcform">print</mods:form>
    <mods:extent>xvi, 134, [7] p. : ill., maps ; 28 cm.</mods:extent>
    </mods:physicalDescription>
    <mods:note displayLabel="statement of responsibility">Glen McLaughlin with Nancy H. Mayo.</mods:note>
    <mods:note>Includes bibliographical references (p. xv-xvi) and indexes.</mods:note>
    <mods:note displayLabel="state_node_6" type="state 4">hello</mods:note>
    <mods:note displayLabel="" type="state 5">goodbye</mods:note>
    <mods:subject>
    <mods:geographicCode authority="marcgac">n-us-ca</mods:geographicCode>
    </mods:subject>
    <mods:subject authority="lcsh">
    <mods:topic>Cartography</mods:topic>
    <mods:geographic>California</mods:geographic>
    <mods:topic>History</mods:topic>
    <mods:genre>Sources</mods:genre>
    </mods:subject>
    <mods:subject authority="lcsh">
    <mods:geographic>California</mods:geographic>
    <mods:topic>Maps</mods:topic>
    <mods:topic>Early works to 1800</mods:topic>
    <mods:genre>Bibliography</mods:genre>
    <mods:genre>Catalogs</mods:genre>
    </mods:subject>
    <mods:classification authority="lcc">GA413 .M38 1995</mods:classification>
    <mods:classification authority="ddc" edition="21">912.794</mods:classification>
    <mods:identifier type="local" displayLabel="Symphony Catalog Key">3306259</mods:identifier>
    <mods:identifier type="isbn" invalid="yes">01888126000</mods:identifier>
    <mods:identifier type="lccn">97119748</mods:identifier>
    <mods:identifier type="uri">http://collections.stanford.edu/bookreader-public/view.jsp?id=00021264#1</mods:identifier>
    <mods:location>
    <mods:url usage="primary display">http://collections.stanford.edu/bookreader-public/view.jsp?id=00021264#1</mods:url>
    </mods:location>
    <mods:recordInfo>
    <mods:descriptionStandard>aacr2</mods:descriptionStandard>
    <mods:recordContentSource authority="marcorg">DNA</mods:recordContentSource>
    <mods:recordCreationDate encoding="marc">960319</mods:recordCreationDate>
    <mods:recordIdentifier>a3306259</mods:recordIdentifier>
    </mods:recordInfo>
    </mods:relatedItem>
    </mods:mods>'
    xml = '<mods:mods xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
    <mods:note displayLabel="" type=""/>
    <mods:note displayLabel="general note" type=""/>
    <mods:note displayLabel="general note" type="state_note"/>
    <mods:note displayLabel="general note"/>
    <mods:note displayLabel="general_state_note"/>
    <mods:note displayLabel="state_note"/>
    <mods:note displayLabel="state note" type="state_note"/>
    <mods:note displayLabel="state_note" type=""/>
    <mods:note/>
    <mods:note displayLabel="" type="content"/>
    <mods:note displayLabel="general note" type="content"/>
    <mods:note displayLabel="general_state_note" type="content"/>
    <mods:note displayLabel="state_note" type="content"/>
    <mods:note type="content"/>
    <mods:note displayLabel="" type="statement_of_responsibility"/>
    <mods:note displayLabel="state_node_1" type="statement_of_responsibility"  />
    <mods:note displayLabel="state_note" type="statement_of_responsibility"/>
    <mods:note type="statement_of_responsibility"/>
    <mods:note displayLabel="" type="publications"/>
    <mods:note displayLabel="general note" type="publications"/>
    <mods:note displayLabel="state_note" type="publications"/>
    <mods:note displayLabel="" type="references"/>
    <mods:note displayLabel="general note" type="reference"/>
    <mods:note displayLabel="general note" type="references"/>
    <mods:note displayLabel="citation/reference"/>
    <mods:note displayLabel="" type="state 1"/>
    <mods:note displayLabel="general note" type="state 1"/>
    <mods:note displayLabel="state_node_1" type="state 1"/>
    <mods:note displayLabel="state_node_1"/>
    <mods:note displayLabel="" type="state 2"/>
    <mods:note displayLabel="general note" type="state 2"/>
    <mods:note displayLabel="State 2" type="state_note"/>
    <mods:note displayLabel="state_node_2"/>
    <mods:note displayLabel="state_node_4" type="state 2"/>
    <mods:note displayLabel="" type="state 3"/>
    <mods:note displayLabel="general note" type="state 3"/>
    <mods:note displayLabel="state_node_3"/>
    <mods:note displayLabel="state_node_4" type="state 3"/>
    <mods:note displayLabel="state_node_5" type="state 3"/>
    <mods:note displayLabel="state_node_4" type="state_note"/>
    <mods:note displayLabel="state_node_4"/>
    <mods:note displayLabel="state_node_6" type="state 4"/>
    <mods:note displayLabel="" type="state 5"/>
    <mods:note displayLabel="state_node_5"/>
    <mods:note displayLabel="state_node_7" type="state 5"/>
    <mods:note displayLabel="State 6" type="state_note"/>
    <mods:note displayLabel="state_node_6"/>
    <mods:note displayLabel="state_node_8" type="state 6"/>
    <mods:note displayLabel="" type="state 7"/>
    <mods:note displayLabel="state_node_7"/>
    <mods:note displayLabel="state_node_9" type="state 7"/>
    <mods:note displayLabel="state_node_8"/>
    <mods:note displayLabel="state_node_10" type="state 8"/>
    <mods:note displayLabel="state_node_9"/>
    <mods:note displayLabel="state_node_11" type="state 9"/>
    <mods:note displayLabel="state_node_10"/>
    <mods:note displayLabel="state_node_2" type="state 10"/>
    <mods:note displayLabel="state_node_11"/>
    <mods:note displayLabel="state_node_5" type="state 11"/>
    <mods:note displayLabel="location_code" type="content"/>
    <mods:note displayLabel="location_code"/>
    </mods:mods>'
    @doc = Nokogiri::XML(xml)
    subject = '<mods:mods xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd"><mods:subject>
    <mods:topic>America--Maps--To 1800</mods:topic>
    <mods:topic>America--Maps--1675</mods:topic>
    <mods:topic>California as an island--Maps--1675</mods:topic>
    <mods:topic>Pacific Ocean--Maps--To 1800</mods:topic>
    </mods:subject>'
    @subject_doc = Nokogiri::XML(subject)
    identifier = '<mods:mods xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
    <mods:identifier displayLabel="Original McLaughlin Book Number (1995 edition) "
    <mods:identifier displayLabel="Original McLaughlin book number (1995 edition) with latest state information"/>
    <mods:identifier displayLabel="Updated McLaughlin Book Number"/>
    <mods:identifier displayLabel="Updated McLaughlin Book Number with latest state information"/>
    <mods:identifier displayLabel="Post publication map number"/>
    <mods:identifier displayLabel="Post publication map number with latest state information"/>

    <mods:identifier displayLabel="FileMaker Pro Record Number"/>
    <mods:identifier displayLabel="FileMaker Pro record number with latest state information"/>
    <mods:identifier displayLabel="Stanford University Archives Id"/>
    <mods:identifier displayLabel="New Stanford map number"/>
    <mods:identifier displayLabel="New Stanford map number with latest state information"/>
    <mods:identifier displayLabel="SU DRUID"/>
    <mods:identifier displayLabel="entry_number"/>
    <mods:identifier displayLabel="call_number"/>
    <mods:identifier displayLabel="book_number"/>
    <mods:identifier displayLabel="record_number"/>
    <mods:identifier displayLabel="filename"/>'
    @identifier_doc = Nokogiri::XML(identifier)
    empty_nodes = '
    <mods:mods xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
    <mods:mods>
    <mods:name>
    <mods:role>
    <mods:roleTermtype="text"authority="marcrelator"/>
    </mods:role>
    </mods:name>

    <mods:titleInfotype="main">
    <mods:nonSort/>
    <mods:title>World Map Untitled</mods:title>
    <mods:subTitle/>
    <mods:partNumber/>
    <mods:partName/>
    </mods:titleInfo

    <mods:physicalDescription>
    <mods:extent/>
    </mods:physicalDescription>
    <mods:location>
    <mods:physicalLocation/>
    <mods:url usage="primary display" access=""/>
    </mods:location>

    <mods:subject authority="keyword">
    <mods:topic>hello</mods:topic>
    </mods:subject>

    <mods:subject>
    <mods:cartographics>
    <mods:scale/>
    <mods:coordinates>W0200000 E1600000 N900000 S900000</mods:coordinates>
    <mods:projection/>
    </mods:cartographics>
    </mods:subject>
    </mods:mods>
    '
    @emptynode_doc = Nokogiri::XML(empty_nodes)
    carto = '
    <mods:mods xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
    <mods:mods>
    <mods:cartographics>

    <mods:scale>something</mods:scale>
    <mods:coordinates>something</mods:coordinates>
    <mods:projection>something</mods:projection>
    </mods:cartographics>

    </mods:mods>
    '
    @carto_doc = Nokogiri::XML(carto)
    collection_record = '<mods:mods xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
    <mods:mods>
    <mods:typeOfResource collection="yes"/>
    </mods:mods/>
    '
    @notes_doc = '<mods:mods xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
  <mods:typeOfResource>cartographic</mods:typeOfResource>
  <mods:genre authority="marcgt">map</mods:genre>
  <mods:genre>Digital Maps</mods:genre>
  <mods:genre>Early Maps</mods:genre>
  <mods:accessCondition displayLabel="Copyright Stanford University. Stanford, CA 94305. (650) 723-2300." type="useAndReproduction">Stanford University Libraries and Academic Information Resources - Terms of Use SULAIR Web sites are subject to Stanford Universitys standard Terms of Use (See http://www.stanford.edu/home/atoz/terms.html) These terms include a limited personal, non-exclusive, non-transferable license to access and use the sites, and to download - where permitted - material for personal, non-commercial, non-display use only. Please contact the University Librarian to request permission to use SULAIR Web sites and contents beyond the scope of the above license, including but not limited to republication to a group or republishing the Web site or parts of the Web site. SULAIR provides access to a variety of external databases and resources, which sites are governed by their own Terms of Use, as well as contractual access restrictions. The Terms of Use on these external sites always govern the data available there. Please consult with library staff if you have questions about data access and availability.</mods:accessCondition>
  <mods:identifier displayLabel="Post publication map number" type="local">511</mods:identifier>
  <mods:titleInfo>
    <mods:title>GEOGRAPHY.</mods:title>
  </mods:titleInfo>
  <mods:originInfo>
    <mods:publisher>J. Wilkes</mods:publisher>
    <mods:place>
      <mods:placeTerm>[London]</mods:placeTerm>
    </mods:place>
    <mods:dateCreated keyDate="yes">1807</mods:dateCreated>
  </mods:originInfo>
  <mods:physicalDescription>
    <mods:extent>7.8 cm. in diameter on sheet 23.8 x 18.0 cm.</mods:extent>
  </mods:physicalDescription>
  <mods:name authority="naf" type="personal" xlink:href="http://id.loc.gov/authorities/names/nr91033752">
    <mods:role>
      <mods:roleTerm>creator</mods:roleTerm>
    </mods:role>
    <mods:namePart>Wilkes, John, of Milland House, Sussex</mods:namePart>
  </mods:name>
  <mods:name authority="naf" type="personal" xlink:href="http://id.loc.gov/authorities/names/no2010024699">
    <mods:role>
      <mods:roleTerm>engraver</mods:roleTerm>
    </mods:role>
    <mods:namePart>Pass, J.</mods:namePart>
  </mods:name>
  <mods:genre>Separate Map</mods:genre>
  <mods:note>Page showing five hemispherical maps of the world. Hemispheres numbered &#x201C;2&#x201D; and &#x201C;4&#x201D; show California as an unlabeled island from a polar and oblique projection, respectively.</mods:note>
  <mods:note>J. Pass sculp (lower right).</mods:note>
  <mods:note>Published as the Act directs, Jany. 1st 1807, by J. Wilkes (lower middle).</mods:note>
  <mods:note>Plate III. (upper right).</mods:note>
  <mods:note type="publications">Issued in his: Encyclopaedia londinensis; or, universal dictionary of arts, sciences &amp; literature ... London, Adlard, 1810-1829.</mods:note>
  <mods:note>Supplementary title below maps: Projections of the Sphere, and common Terrestrial Globe.</mods:note>
  <mods:note type="references">UCLA.</mods:note>
  <mods:note displayLabel="Statement of responsibility" type="statement_of_responsibility">[John Wilkes]</mods:note>
  <mods:subject>
    <mods:topic>California as an island--Maps</mods:topic>
  </mods:subject>
  <mods:subject>
    <mods:topic>Northern Hemisphere--Maps</mods:topic>
  </mods:subject>
</mods:mods>'
    @collection_record = Nokogiri::XML(collection_record)
  end
  context 'schema_validate' do
    it 'should validate a document' do
      doc = Nokogiri.XML(@full_doc) do |config|
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
