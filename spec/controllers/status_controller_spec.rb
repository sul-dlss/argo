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
    	Dor::Item.any_instance.stub(:save) do 
			save_count=1
			end
    	Dor::Item.stub(:dirty)
			#the time has to be incorrectly offset to gmt like it is in the logs, hence the additional -420 minutes
			File.stub(:new){StringIO.new("W, ["+437.minutes.ago.strftime('%Y-%m-%d %H:%M:%S ')+". #27663]  WARN -- :  updated solr index for druid:gb234tt5124")}
			get 'log',:test_obj=>'druid:bs846vw6460'
    	save_count.should == 1
    end
  end

end
