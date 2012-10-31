require 'spec_helper'

describe StatusController do

  describe "GET 'log'" do
    it "returns http success" do
			File.stub(:new){StringIO.new("W, ["+DateTime.now.strftime('%Y-%m-%d %H:%M:%S ')+". #27663]  WARN -- :  updated solr index for druid:gb234tt5124")}
			get 'log'
      response.code.should =='200'
    end

    it "fails if the last log time was more than 15 minutes ago " do
			#the time has to be incorrectly offset to gmt like it is in the logs, hence the additional -420 minutes
			File.stub(:new){StringIO.new("W, ["+437.minutes.ago.strftime('%Y-%m-%d %H:%M:%S ')+". #27663]  WARN -- :  updated solr index for druid:gb234tt5124")}
			get 'log'
      response.code.should == '500' 
    end
    it 'should trigger a Dor:Item.save when nothing has been indexed recently and a test druid was passed in' do
    	save_count=0
    	@item=mock(Dor::Item)
    	@item.should_receive(:save) 
    	@item.stub(:dirty)
    	mock_md=mock(Dor::IdentityMetadataDS)
    	mock_md.stub(:content)
    	mock_md.stub(:ng_xml).and_return('hello')
    	mock_md.stub(:dirty=)
    	@item.stub(:identityMetadata).and_return(mock_md)
    	Dor::Item.stub(:find).and_return(@item)
			#the time has to be incorrectly offset to gmt like it is in the logs, hence the additional -420 minutes
			File.stub(:new){StringIO.new("W, ["+437.minutes.ago.strftime('%Y-%m-%d %H:%M:%S ')+". #27663]  WARN -- :  updated solr index for druid:gb234tt5124")}
			get 'log',:test_obj=>'druid:bs846vw6460'
    end
  end
  describe 'GET indexer' do
    it 'should get the indexer status' do
      
      get 'indexer'
      response.body.should 
    end
  end

end
