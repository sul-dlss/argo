require 'spec_helper'

describe DorController do
  describe "reindex" do
    it "should reindex an object" do
      log_in_as_mock_user(subject)
      mock_obj = mock()
      controller.stub(:archive_workflows)
      Dor.should_receive(:load_instance).with('asdf:1234').and_return(mock_obj)
      mock_obj.should_receive(:to_solr).and_return({:id => 'asdf:1234'})
      Dor::SearchService.solr.should_receive(:add).with(hash_including(:id => 'asdf:1234'), instance_of(Hash))
      get :reindex, :pid => 'asdf:1234'
    end
   
    it 'should trigger archiving a completed workflow' do
      log_in_as_mock_user(subject)
      item = instantiate_fixture("druid_bb001zc5754", Dor::Item)
      Dor.should_receive(:load_instance).with('druid:bb001zc5754').and_return(item)
      item.workflows.should_receive(:content).and_return '<workflows objectId="druid:bx756pk3634">
      <workflow repository="dor" objectId="druid:bx756pk3634" id="accessionWF">
      <process  lifecycle="submitted" elapsed="0.0" archived="true" attempts="1" datetime="2013-05-15T16:39:49-0700" status="completed" name="start-accession"/>
      <process  elapsed="0.516" archived="true" attempts="1" datetime="2013-05-15T16:46:38-0700" status="completed" name="content-metadata"/>
      <process  elapsed="0.984" archived="true" attempts="1" datetime="2013-05-15T16:46:41-0700" status="completed" name="rights-metadata"/>
      <process  lifecycle="described" elapsed="0.238" archived="true" attempts="1" datetime="2013-05-15T16:46:44-0700" status="completed" name="descriptive-metadata"/>
      <process  elapsed="3.375" archived="true" attempts="1" datetime="2013-05-15T16:54:16-0700" status="completed" name="remediate-object"/>
      <process  elapsed="0.5" archived="true" attempts="1" datetime="2013-05-15T16:54:37-0700" status="completed" name="technical-metadata"/>
      <process  elapsed="1.299" archived="true" attempts="1" datetime="2013-05-15T17:03:43-0700" status="completed" name="shelve"/>
      <process  elapsed="0.261" archived="true" attempts="1" datetime="2013-05-15T17:07:25-0700" status="completed" name="provenance-metadata"/>
      <process  lifecycle="published" elapsed="0.315" archived="true" attempts="1" datetime="2013-05-15T17:17:06-0700" status="completed" name="publish"/>
      <process  elapsed="0.0" archived="true" attempts="3" datetime="2013-05-22T11:51:08-0700" status="completed" name="sdr-ingest-transfer"/>
      <process  lifecycle="deposited" elapsed="0.0" archived="true" attempts="1" datetime="2013-05-22T11:51:36-0700" status="completed" name="sdr-ingest-received"/>
      <process  lifecycle="accessioned" elapsed="0.0" archived="true" attempts="1" datetime="2013-05-22T11:52:02-0700" status="completed" name="end-accession"/>
      </workflow>
      </workflows>'
      item.should_receive(:to_solr).and_return({:id => 'druid:bb001zc5754'})
      Dor::WorkflowService.should_receive(:archive_workflow).with('dor','druid:bb001zc5754','accessionWF')
      get :reindex, :pid => 'druid:bb001zc5754'
       
    end
   
    it 'should trigger archiving if there is a skipped step and the rest are completed' do
      log_in_as_mock_user(subject)
      item = instantiate_fixture("druid_bb001zc5754", Dor::Item)
      Dor.should_receive(:load_instance).with('druid:bb001zc5754').and_return(item)
      item.workflows.should_receive(:content).and_return '<workflows objectId="druid:bx756pk3634">
      <workflow repository="dor" objectId="druid:bx756pk3634" id="accessionWF">
      <process  lifecycle="submitted" elapsed="0.0" archived="true" attempts="1" datetime="2013-05-15T16:39:49-0700" status="completed" name="start-accession"/>
      <process  elapsed="0.516" archived="true" attempts="1" datetime="2013-05-15T16:46:38-0700" status="skipped" name="content-metadata"/>
      <process  elapsed="0.984" archived="true" attempts="1" datetime="2013-05-15T16:46:41-0700" status="completed" name="rights-metadata"/>
      <process  lifecycle="described" elapsed="0.238" archived="true" attempts="1" datetime="2013-05-15T16:46:44-0700" status="completed" name="descriptive-metadata"/>
      <process  elapsed="3.375" archived="true" attempts="1" datetime="2013-05-15T16:54:16-0700" status="completed" name="remediate-object"/>
      <process  elapsed="0.5" archived="true" attempts="1" datetime="2013-05-15T16:54:37-0700" status="completed" name="technical-metadata"/>
      <process  elapsed="1.299" archived="true" attempts="1" datetime="2013-05-15T17:03:43-0700" status="completed" name="shelve"/>
      <process  elapsed="0.261" archived="true" attempts="1" datetime="2013-05-15T17:07:25-0700" status="completed" name="provenance-metadata"/>
      <process  lifecycle="published" elapsed="0.315" archived="true" attempts="1" datetime="2013-05-15T17:17:06-0700" status="completed" name="publish"/>
      <process  elapsed="0.0" archived="true" attempts="3" datetime="2013-05-22T11:51:08-0700" status="completed" name="sdr-ingest-transfer"/>
      <process  lifecycle="deposited" elapsed="0.0" archived="true" attempts="1" datetime="2013-05-22T11:51:36-0700" status="completed" name="sdr-ingest-received"/>
      <process  lifecycle="accessioned" elapsed="0.0" archived="true" attempts="1" datetime="2013-05-22T11:52:02-0700" status="completed" name="end-accession"/>
      </workflow>
      </workflows>'
      item.should_receive(:to_solr).and_return({:id => 'druid:bb001zc5754'})
      Dor::WorkflowService.should_receive(:archive_workflow).with('dor','druid:bb001zc5754','accessionWF')
      get :reindex, :pid => 'druid:bb001zc5754'
       
    end
    it 'shouldnt trigger archiving for an archived workflow' do
      log_in_as_mock_user(subject)
      item = instantiate_fixture("druid_bb001zc5754", Dor::Item)
      Dor.should_receive(:load_instance).with('druid:bb001zc5754').and_return(item)
      item.workflows.should_receive(:content).and_return '<workflows objectId="druid:bx756pk3634">
      <workflow repository="dor" objectId="druid:bx756pk3634" id="accessionWF">
      <process version="1" lifecycle="submitted" elapsed="0.0" archived="true" attempts="1" datetime="2013-05-15T16:39:49-0700" status="completed" name="start-accession"/>
      <process version="1" elapsed="0.516" archived="true" attempts="1" datetime="2013-05-15T16:46:38-0700" status="completed" name="content-metadata"/>
      <process version="1" elapsed="0.984" archived="true" attempts="1" datetime="2013-05-15T16:46:41-0700" status="completed" name="rights-metadata"/>
      <process version="1" lifecycle="described" elapsed="0.238" archived="true" attempts="1" datetime="2013-05-15T16:46:44-0700" status="completed" name="descriptive-metadata"/>
      <process version="1" elapsed="3.375" archived="true" attempts="1" datetime="2013-05-15T16:54:16-0700" status="completed" name="remediate-object"/>
      <process version="1" elapsed="0.5" archived="true" attempts="1" datetime="2013-05-15T16:54:37-0700" status="completed" name="technical-metadata"/>
      <process version="1" elapsed="1.299" archived="true" attempts="1" datetime="2013-05-15T17:03:43-0700" status="completed" name="shelve"/>
      <process version="1" elapsed="0.261" archived="true" attempts="1" datetime="2013-05-15T17:07:25-0700" status="completed" name="provenance-metadata"/>
      <process version="1" lifecycle="published" elapsed="0.315" archived="true" attempts="1" datetime="2013-05-15T17:17:06-0700" status="completed" name="publish"/>
      <process version="1" elapsed="0.0" archived="true" attempts="3" datetime="2013-05-22T11:51:08-0700" status="completed" name="sdr-ingest-transfer"/>
      <process version="1" lifecycle="deposited" elapsed="0.0" archived="true" attempts="1" datetime="2013-05-22T11:51:36-0700" status="completed" name="sdr-ingest-received"/>
      <process version="1" lifecycle="accessioned" elapsed="0.0" archived="true" attempts="1" datetime="2013-05-22T11:52:02-0700" status="completed" name="end-accession"/>
      </workflow>
      </workflows>'
      item.should_receive(:to_solr).and_return({:id => 'druid:bb001zc5754'})
      Dor::WorkflowService.should_not_receive(:archive_workflow)
      get :reindex, :pid => 'druid:bb001zc5754'
    end
  end
  
  describe 'dor indexing' do
    before :each do
      log_in_as_mock_user(subject)
      item = instantiate_fixture("druid_bb001zc5754", Dor::Item)
      item.descMetadata.stub(:new?).and_return(false)
      item.descMetadata.stub(:ng_xml).and_return(Nokogiri::XML('<mods:mods xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="3.3" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">
      <mods:titleInfo>
      <mods:title>AMERICA cum Supplementis Poly-Glot-tis</mods:title>
      </mods:titleInfo>
      </mods:mods>'))
      item.workflows.should_receive(:content).and_return '<workflows objectId="druid:bx756pk3634"></workflows>'
      item.stub(:milestones).and_return []
      item.stub(:new_version_open?).and_return false
      item.stub(:archive_workflows)
      @solr_doc=item.to_solr
    end
    
    it 'the indexer should generate gryphondor fields' do
      @solr_doc[:sw_title_sort_facet].should == "AMERICA cum Supplementis PolyGlottis"
    end
    
    it 'all of the gdor fields should be present in the hash' do
      
      @solr_doc.has_key?(:sw_title_245a_search_facet_facet).should == true
      @solr_doc.has_key?(:sw_title_245_search_facet_facet).should == true
      @solr_doc.has_key?(:sw_title_variant_search_facet_facet).should == true
      @solr_doc.has_key?(:sw_title_sort_facet).should == true
      @solr_doc.has_key?(:sw_title_245a_display_facet).should == true
      @solr_doc.has_key?(:sw_title_display_facet).should == true
      @solr_doc.has_key?(:sw_title_full_display_facet).should == true
      @solr_doc.has_key?(:sw_author_1xx_search_facet_facet).should == true
      @solr_doc.has_key?(:sw_author_7xx_search_facet_facet).should == true
      @solr_doc.has_key?(:sw_author_person_facet_facet).should == true
      @solr_doc.has_key?(:sw_author_other_facet_facet).should == true
      @solr_doc.has_key?(:sw_author_corp_display_facet).should == true
      @solr_doc.has_key?(:sw_author_meeting_display_facet).should == true
      @solr_doc.has_key?(:sw_author_person_display_facet).should == true
      @solr_doc.has_key?(:sw_author_person_full_display_facet).should == true
      @solr_doc.has_key?(:sw_topic_search_facet_facet).should == true
      @solr_doc.has_key?(:sw_geographic_search_facet_facet).should == true
      @solr_doc.has_key?(:sw_subject_other_search_facet_facet).should == true
      @solr_doc.has_key?(:sw_subject_other_subvy_search_facet_facet).should == true
      @solr_doc.has_key?(:sw_subject_all_search_facet_facet).should == true
      @solr_doc.has_key?(:sw_topic_facet_facet).should == true
      @solr_doc.has_key?(:sw_geographic_facet_facet).should == true
      @solr_doc.has_key?(:sw_era_facet_facet).should == true
      @solr_doc.has_key?(:sw_language_facet).should == true
      @solr_doc.has_key?(:sw_pub_search_facet_facet).should == true
      @solr_doc.has_key?(:sw_pub_date_sort_facet).should == true
      @solr_doc.has_key?(:sw_pub_date_group_facet_facet).should == true
      @solr_doc.has_key?(:sw_pub_date_facet).should == true
      @solr_doc.has_key?(:sw_pub_date_display_facet).should == true
      @solr_doc.has_key?(:sw_all_search_facet_facet).should == true
      @solr_doc.has_key?(:sw_format_facet).should == true
    end
    it 'all of the solr fields argo depends on should be in a solr doc generated by to_solr' do
      pending 
      
    end
  end

  describe "delete_from_index" do
    it "should remove an object from the index" do
      log_in_as_mock_user(subject)
      Dor::SearchService.solr.should_receive(:delete_by_id).with('asdf:1234')
      get :delete_from_index, :pid => 'asdf:1234'
    end
  end
  
  describe "republish" do
    it 'should republish' do
      log_in_as_mock_user(subject)
      mock_item=mock()
      mock_item.should_receive(:publish_metadata)
      Dor::Item.stub(:find).and_return(mock_item)
      get :republish, :pid => 'druid:123'
    end
  end
  
end
