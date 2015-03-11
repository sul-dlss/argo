require 'spec_helper'

describe SolrDocument, :type => :model do
  describe 'get_milestones' do
    it 'should build an empty listing if passed an empty doc' do
      milestones=get_milestones(Hash.new)
      milestones.each do |key,value|
        expect(value[:time]).to eq 'pending'
      end
    end
    it 'should generate a correct lifecycle with the old format that lacks version info' do
      lifecycle_data=Array.new
      lifecycle_data << 'registered:2012-02-25T01:40:57Z'
      doc={ 'lifecycle_display' => lifecycle_data }
      
      versions=get_milestones(doc)
      versions.each do |version,milestones|
        milestones.each do |key,value|
          expect(version).to eq(1)
          if value[:display]=='Registered'
            expect(I18n.l(value[:time])).to eq('2012-02-24 05:40PM')
          else
            expect(value[:time]).to eq 'pending'
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
      expect(versions['1'].length).to eq(8)
      expect(versions['1']['registered'].nil?).to eq(false)
      expect(versions['2'].length).to eq(8)
      expect(versions['2']['registered'].nil?).to eq(true)
      expect(versions['2']['opened'].nil?).to eq(false)
      versions.each do |version,milestones|
        milestones.each do|key,value|
      
          case value[:display]
            when 'Registered'
              expect(I18n.l(value[:time])).to eq('2012-02-24 05:40PM') #the hour/minute here is wrong...dont know why
              expect(version).to eq('1')                               #registration is always only v1
            when 'Opened'
              expect(I18n.l(value[:time])).to eq('2012-02-24 05:39PM') #the hour/minute here is wrong...dont know why
              expect(version).to eq('2')
            else
              expect(value[:time]).to eq('pending')
          end
        end
      end
    end  
  end
  describe 'get_versions' do
    it 'should build a version hash' do
      data=[]
      data << '1;1.0.0;Initial version'
      data << '2;1.1.0;Minor change'
      doc={'versions_display' => data}
      versions=get_versions(doc)
      expect(versions['1'][:tag]).to eq('1.0.0')
    end
  end
  
end
