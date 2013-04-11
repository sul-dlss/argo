require 'spec_helper'
describe ItemsHelper do
  before(:each) do
    @full_doc='  <mods:mods xmlns:xxi="http://orbeon.org/oxf/xml/xinclude" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xbl="http://www.w3.org/ns/xbl" xmlns:exforms="http://www.exforms.org/exf/1-0" xmlns:pipeline="java:org.orbeon.oxf.processor.pipeline.PipelineFunctionLibrary" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:fr="http://orbeon.org/oxf/xml/form-runner" xmlns:dl="http://dl.lib.brown.edu/editor/mods/dl" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xxforms="http://orbeon.org/oxf/xml/xforms">
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
    xml='<mods:mods xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
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
    @doc=Nokogiri::XML(xml)
    subject='<mods:mods xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd"><mods:subject>
    <mods:topic>America--Maps--To 1800</mods:topic>
    <mods:topic>America--Maps--1675</mods:topic>
    <mods:topic>California as an island--Maps--1675</mods:topic>
    <mods:topic>Pacific Ocean--Maps--To 1800</mods:topic>
    </mods:subject>'
    @subject_doc=Nokogiri::XML(subject)
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
    @identifier_doc=Nokogiri::XML(identifier)
    empty_nodes='
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
    @emptynode_doc=Nokogiri::XML(empty_nodes)
    carto='
    <mods:mods xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
    <mods:mods>
    <mods:cartographics>

    <mods:scale>something</mods:scale>
    <mods:coordinates>something</mods:coordinates>
    <mods:projection>something</mods:projection>
    </mods:cartographics>

    </mods:mods>
    '
    @carto_doc=Nokogiri::XML(carto)
    collection_record='<mods:mods xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
    <mods:mods>
    <mods:typeOfResource collection="yes"/>
    </mods:mods/>
    '
    @collection_record=Nokogiri::XML(collection_record)
  end
  it 'should remove useless displayLabels and types' do
    count=0
    mclaughlin_cleanup_notes @doc
    @doc.search('//mods:note','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      if node.attribute_nodes().length==0 
        count+=1
      end
    end
    count.should == 14
  end
  it 'should normalize statements of responsibility' do
    count=0
    mclaughlin_cleanup_statement @doc
    @doc.search('//mods:note','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      if node['displayLabel'] == 'Statement of responsibility' and node['type'] == 'statement_of_responsibility'
        count+=1
      end
    end
    count.should == 4
  end
  it 'should normalize publication statements' do
    count=0
    mclaughlin_cleanup_publication @doc
    @doc.search('//mods:note','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      if node['displayLabel'] == 'Publications' and node['type'] == 'publications'
        count+=1
      end
    end
    count.should == 3
  end
  it 'should normalize references' do
    count=0
    mclaughlin_cleanup_references @doc
    @doc.search('//mods:note','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      if node['displayLabel'] == 'References' and node['type'] == 'reference'
        count+=1
      end
    end
    count.should == 4
  end
  it 'should normalize states' do
    count=0
    mclaughlin_cleanup_states @doc
    @doc.search('//mods:note','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      if node['displayLabel'] == 'State 1' and node['type'] == nil
        count+=1
      end
    end
    count.should == 5
  end
  it 'should normalize state2' do
    count = 0
    mclaughlin_cleanup_states @doc
    @doc.search('//mods:note','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      if node['displayLabel'] == 'State 2'
        count+=1
      end
    end
    count.should == 5
  end
  it 'should normalize state 3' do
    count = 0
    mclaughlin_cleanup_states @doc
    @doc.search('//mods:note','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      if node['displayLabel'] == 'State 3'
        count+=1
      end
    end
    count.should == 5
  end
  it 'should normalize state 10' do
    count = 0
    mclaughlin_cleanup_states @doc
    @doc.search('//mods:note','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      if node['displayLabel'] == 'State 10'
        count+=1
      end
    end
    count.should == 2
  end
  it 'should normalize state 11' do
    count = 0
    mclaughlin_cleanup_states @doc
    @doc.search('//mods:note','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      if node['displayLabel'] == 'State 11'
        count+=1
      end
    end
    count.should == 2
  end
  it 'should reorder states' do
    count = 0
    mclaughlin_cleanup_states @doc
    mclaughlin_reorder_states @doc
    @doc = Nokogiri.XML(@doc.to_s) do |config|
      config.default_xml.noblanks
    end
  end
  it 'should ignore some fields' do
    count = 0
    mclaughlin_ignore_fields @doc
    @doc.search('//mods:note','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      if node['displayLabel'] == 'location_code'
        count+=1
      end
    end
    count.should == 0
  end
  it 'should split subjects' do
    count = 0
    mclaughlin_fix_subjects @subject_doc
    @subject_doc.search('//mods:subject','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      count+=1
    end
    count.should == 4
  end
  it 'should prune identifiers' do
    count = 0
    mclaughlin_prune_identifiers @identifier_doc
    @identifier_doc.search('//mods:identifier','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      count+=1
    end
    count.should == 6
  end
  it 'should remove empty nodes' do
    count = 0
    remove_empty_nodes @emptynode_doc
    @emptynode_doc.search('//mods:nonSort','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      count+=1
    end
    count.should == 0
  end
  it 'should reorder carographics children' do
    mclaughlin_reorder_cartographics @carto_doc
    count = 0
    @carto_doc.search('//mods:cartographics','mods'=>'http://www.loc.gov/mods/v3').each do |node|
      count+=1
      children=node.children
      children[4].name.should == 'scale'
      children[5].name.should == 'projection'
    end
    count.should == 1

  end
  it 'should fix a mclaughlin record' do
    doc = Nokogiri.XML(@full_doc) do |config|
      config.default_xml.noblanks
    end
    remove_empty_nodes doc
    doc.search('/mods:mods/mods:originInfo/mods:place','mods'=>'http://www.loc.gov/mods/v3').length.should == 0
    doc.search('/mods:mods/mods:originInfo','mods'=>'http://www.loc.gov/mods/v3').length.should == 1
  end
  it 'should run all remediations on a mclaughlin doc' do
    
    doc = Nokogiri.XML(@full_doc) do |config|
      config.default_xml.noblanks
    end
    mclaughlin_remediation(doc)
    #need an assertion here...
  end
  it 'should validate a document' do
    doc = Nokogiri.XML(@full_doc) do |config|
      config.default_xml.noblanks
    end
    schema_validate(doc).length.should == 6
  end
  it 'should preserve the empty typeofresource with collection=yes' do
    remove_empty_nodes(@collection_record)
    @collection_record.search('//mods:typeOfResource','mods'=>'http://www.loc.gov/mods/v3').length.should == 1
  end
  it 'should strip leading and trailing whitespaces' do
    doc = Nokogiri.XML(@full_doc) do |config|
      config.default_xml.noblanks
    end
    remove_empty_nodes doc
    doc.search('/mods:mods/mods:titleInfo/mods:title','mods'=>'http://www.loc.gov/mods/v3').first.text.should == "A New and Curious Map of the World"

  end
  it 'should remove linefeeds from accessconditions' do
    doc = Nokogiri.XML(@full_doc) do |config|
      config.default_xml.noblanks
    end
    mclaughlin_remove_newlines doc
    doc.search('/mods:mods/mods:accessCondition','mods'=>'http://www.loc.gov/mods/v3').first.text.should == "Stanford University Libraries and Academic Information Resources - Terms ofUse SULAIR Web sites are subject to Stanford University's standard Terms ofUse (See http://www.stanford.edu/home/atoz/terms.html) These terms include alimited personal, non-exclusive, non-transferable license to access and usethe sites, and to download - where permitted - material for personal,non-commercial, non-display use only. Please contact the UniversityLibrarian to request permission to use SULAIR Web sites and contents beyondthe scope of the above license, including but not limited to republicationto a group or republishing the Web site or parts of the Web site. SULAIRprovides access to a variety of external databases and resources, whichsites are governed by their own Terms of Use, as well as contractual accessrestrictions. The Terms of Use on these external sites always govern thedata available there. Please consult with library staff if you havequestions about data access and availability."
  end
  it 'should pass a discoverablilty check with a mclaughlin doc' do
    doc = Nokogiri.XML(@full_doc) do |config|
      config.default_xml.noblanks
    end
    errors=mods_discoverabable(doc)
    errors.length.should == 0
  end
end