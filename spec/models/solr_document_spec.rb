require 'spec_helper'

describe SolrDocument, :type => :model do
  describe 'get_milestones' do
    it 'should build an empty listing if passed an empty doc' do
      milestones = SolrDocument.new({}).get_milestones
      milestones.each do |key, value|
        expect(value).to match a_hash_excluding(:time)
      end
    end
    it 'should generate a correct lifecycle with the old format that lacks version info' do
      doc = SolrDocument.new({ 'lifecycle_ssim' => ['registered:2012-02-25T01:40:57Z'] })

      versions = doc.get_milestones
      expect(versions.keys).to eq [1]
      expect(versions).to match a_hash_including(
        1 => a_hash_including(
          'registered' => { :time => be_a_kind_of(DateTime) }
        )
      )
      versions[1].each do |key, value|
        if key == 'registered'
          expect(value[:time].to_s(:iso8601)).to eq('2012-02-25T01:40:57+00:00')
        else
          expect(value[:time]).to be_nil
        end
      end
    end
    it 'should recognize versions and bundle versions together' do
      lifecycle_data = ['registered:2012-02-25T01:40:57Z;1', 'opened:2012-02-25T01:39:57Z;2']
      versions = SolrDocument.new({ 'lifecycle_ssim' => lifecycle_data }).get_milestones
      expect(versions['1'].size).to eq(8)
      expect(versions['2'].size).to eq(8)
      expect(versions['1']['registered']).not_to be_nil
      expect(versions['2']['registered']).to be_nil
      expect(versions['2']['opened']).not_to be_nil
      expect(versions).to match a_hash_including(
        '1' => a_hash_including(
          'registered' => {
            :time => be_a_kind_of(DateTime)
          }
        ),
        '2' => a_hash_including(
          'opened' => {
            :time => be_a_kind_of(DateTime)
          }
        )
      )
      versions.each do |version, milestones|
        milestones.each do |key, value|
          case key
          when 'registered'
            expect(value[:time]).to be_a_kind_of DateTime
            expect(value[:time].to_s(:iso8601)).to eq('2012-02-25T01:40:57+00:00')
            expect(version).to eq('1') # registration is always only on v1
          when 'opened'
            expect(value[:time]).to be_a_kind_of DateTime
            expect(value[:time].to_s(:iso8601)).to eq('2012-02-25T01:39:57+00:00')
            expect(version).to eq('2')
          else
            expect(value[:time]).to be_nil
          end
        end
      end
    end
  end
  describe 'get_versions' do
    it 'should build a version hash' do
      data = []
      data << '1;1.0.0;Initial version'
      data << '2;1.1.0;Minor change'
      versions = SolrDocument.new({ 'versions_ssm' => data }).get_versions
      expect(versions['1']).to match a_hash_including(:tag => '1.0.0', :desc => 'Initial version')
      expect(versions['2']).to match a_hash_including(:tag => '1.1.0', :desc => 'Minor change')
    end
  end
end
