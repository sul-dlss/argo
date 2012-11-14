require 'spec_helper'

describe SolrDocument do
  describe 'get_milestones' do
    it 'should build an empty listing if passed an empty doc' do
      milestones=get_milestones(Hash.new)
      milestones.each do |key,value|
        value[:time].should=='pending'
      end
    end
    it 'should generate a correct lifecycle with the old format that lacks version info' do
      lifecycle_data=Array.new
      lifecycle_data << 'registered:2012-02-25T01:40:57Z'
      doc={ 'lifecycle_display' => lifecycle_data }
      
      versions=get_milestones(doc)
      versions.each do |version,milestones|
      milestones.each do |key,value|
        version.should == 1
        if value[:display]=='Registered'
          I18n.l(value[:time]).should=='2012-02-24 05:40pm'
        else
          value[:time].should=='pending'
        end
      end
      end
    end
    it 'should recognize versions and bundle versions together' do
      lifecycle_data=Array.new
      lifecycle_data << 'registered:2012-02-25T01:40:57Z;1'
      lifecycle_data << 'opened:2012-02-25T01:39:57Z;2'
      doc={ 'lifecycle_display' => lifecycle_data }
      versions=get_milestones(doc)
      versions['1'].length.should == 8
      versions['1']['registered'].nil?.should == false
      versions['2'].length.should == 8
      versions['2']['registered'].nil?.should == true
      versions['2']['opened'].nil?.should == false
      versions.each do |version,milestones|
      milestones.each do|key,value|
      
        case value[:display]
        when 'Registered'
          I18n.l(value[:time]).should=='2012-02-24 05:40pm' #the hour/minute here is wrong...dont know why
          version.should == '1' #registration is always only v1
        when 'Opened'
          I18n.l(value[:time]).should=='2012-02-24 05:39pm' #the hour/minute here is wrong...dont know why
          version.should == '2'
        else
          value[:time].should=='pending'
        end
        end
      end
    end  
  end
end