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
      milestones=get_milestones(doc)
      milestones.each do |key,value|
        value[:version].should == 1
        if value[:display]=='Registered'
          I18n.l(value[:time]).should=='2012-02-24 05:40pm'
        else
          value[:time].should=='pending'
        end
      end
    end
    it 'should recognize versions and bundle versions together' do
      lifecycle_data=Array.new
      lifecycle_data << '1:registered:2012-02-25T01:40:57Z'
      lifecycle_data << '2:opened:2012-02-25T01:39:57Z'
      doc={ 'lifecycle_display' => lifecycle_data }
      milestones=get_milestones(doc)
      milestones.each do |key,value|
        case value[:display]
        when 'Registered'
          I18n.l(value[:time]).should=='2012-02-24 05:40pm' #the hour/minute here is wrong...dont know why
          value[:version].should == 1 #registration is always only v1
        when 'Opened'
          I18n.l(value[:time]).should=='2012-02-24 05:39pm' #the hour/minute here is wrong...dont know why
        else
          value[:time].should=='pending'
        end
      end
    end  
  end
end