require 'spec_helper'

describe DorController do
  describe "reindex" do
    it "should reindex an object" do
      mock_druid = 'asdf:1234'
      mock_logger = double()
      mock_obj = double()

      log_in_as_mock_user(subject)

      controller.stub(:index_logger).and_return(mock_logger)
      Argo::Config.stub(:date_format_str).and_return('%Y-%m-%d %H:%M:%S.%L') # doesn't get pulled from config file, which leads to test failure

      Dor.should_receive(:load_instance).with(mock_druid).and_return(mock_obj)
      mock_obj.should_receive(:to_solr).and_return({:id => mock_druid})
      Dor::SearchService.solr.should_receive(:add).with(hash_including(:id => mock_druid), instance_of(Hash))
      mock_logger.should_receive(:info).with("updated index for #{mock_druid}")

      get :reindex, :pid => mock_druid
    end
   
    it "should log the right thing if an object is not found" do
      mock_druid = 'asdf:1234'
      mock_logger = double()

      log_in_as_mock_user(subject)

      controller.stub(:index_logger).and_return(mock_logger)
      Argo::Config.stub(:date_format_str).and_return('%Y-%m-%d %H:%M:%S.%L') # doesn't get pulled from config file, which leads to test failure

      Dor.should_receive(:load_instance).with(mock_druid).and_raise(ActiveFedora::ObjectNotFoundError)
      mock_logger.should_receive(:info).with("failed to update index for #{mock_druid}, object not found in Fedora")

      get :reindex, :pid => mock_druid
    end

    it "should log the right thing if there's an unexpected error" do
      mock_druid = 'asdf:1234'
      mock_logger = double()

      log_in_as_mock_user(subject)

      controller.stub(:index_logger).and_return(mock_logger)
      Argo::Config.stub(:date_format_str).and_return('%Y-%m-%d %H:%M:%S.%L') # doesn't get pulled from config file, which leads to test failure

      err_msg = "didn't see that one coming"
      Dor.should_receive(:load_instance).with(mock_druid).and_raise(err_msg)
      mock_logger.should_receive(:error).with("failed to update index for #{mock_druid}, unexpected error, see main app log")

      expect {get :reindex, :pid => mock_druid}.to raise_error(err_msg)
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
      expect(@solr_doc[:sw_title_sort_facet]).to eq("AMERICA cum Supplementis PolyGlottis")
    end
    
    it 'all of the gdor fields should be present in the hash' do
      expect(@solr_doc.has_key?(:sw_title_245a_search_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_title_245_search_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_title_variant_search_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_title_sort_facet)).to be true
      expect(@solr_doc.has_key?(:sw_title_245a_display_facet)).to be true
      expect(@solr_doc.has_key?(:sw_title_display_facet)).to be true
      expect(@solr_doc.has_key?(:sw_title_full_display_facet)).to be true
      expect(@solr_doc.has_key?(:sw_author_1xx_search_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_author_7xx_search_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_author_person_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_author_other_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_author_corp_display_facet)).to be true
      expect(@solr_doc.has_key?(:sw_author_meeting_display_facet)).to be true
      expect(@solr_doc.has_key?(:sw_author_person_display_facet)).to be true
      expect(@solr_doc.has_key?(:sw_author_person_full_display_facet)).to be true
      expect(@solr_doc.has_key?(:sw_topic_search_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_geographic_search_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_subject_other_search_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_subject_other_subvy_search_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_subject_all_search_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_topic_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_geographic_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_era_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_language_facet)).to be true
      expect(@solr_doc.has_key?(:sw_pub_search_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_pub_date_sort_facet)).to be true
      expect(@solr_doc.has_key?(:sw_pub_date_group_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_pub_date_facet)).to be true
      expect(@solr_doc.has_key?(:sw_pub_date_display_facet)).to be true
      expect(@solr_doc.has_key?(:sw_all_search_facet_facet)).to be true
      expect(@solr_doc.has_key?(:sw_format_facet)).to be true
    end

    it 'all of the solr fields argo depends on should be in a solr doc generated by to_solr' do
      skip
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
      mock_item=double()
      mock_item.should_receive(:publish_metadata_remotely)
      Dor::Item.stub(:find).and_return(mock_item)
      get :republish, :pid => 'druid:123'
    end
  end
end
