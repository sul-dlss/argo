require 'spec_helper'

describe DorController do
  describe "reindex" do
    it "should reindex an object" do
      log_in_as_mock_user(subject)
      mock_obj = mock()
      Dor.should_receive(:load_instance).with('asdf:1234').and_return(mock_obj)
      mock_obj.should_receive(:to_solr).and_return({:id => 'asdf:1234'})
      Dor::SearchService.solr.should_receive(:add).with(hash_including(:id => 'asdf:1234'), instance_of(Hash))
      get :reindex, :pid => 'asdf:1234'
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
