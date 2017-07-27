require 'spec_helper'

describe RegistrationController, :type => :controller do
  before :each do
    @item = double(Dor::Item)
    @current_user = mock_user(is_admin?: true)
    allow(controller).to receive(:current_user).and_return(@current_user)
  end

  describe 'rights_list' do
    it 'should show Stanford as the default if Stanford is the read group and discover is world' do
      content = <<-XML
      <?xml version="1.0"?>
      <rightsMetadata>
        <copyright>
          <human type="copyright">This work is in the Public Domain.</human>
        </copyright>
        <access type="discover">
          <machine>
            <world/>
          </machine>
        </access>
        <access type="read">
          <machine>
            <group>Stanford</group>
          </machine>
        </access>
        <use>
          <human type="creativecommons">Attribution Share Alike license</human>
          <machine type="creativecommons">by-sa</machine>
        </use>
      </rightsMetadata>
      XML

      @item = double(Dor::Item)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      # using content metadata, but any datastream would do
      object_rights = double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      allow(@item).to receive(:default_rights).and_return 'stanford'
      get 'rights_list', params: { :apo_id => 'abc', :format => :xml }
      expect(response.body.include?('Stanford (APO default)')).to eq(true)
    end

    it 'should not show Stanford as the default if the read group is not Stanford' do
      content = <<-XML
      <?xml version="1.0"?>
      <rightsMetadata>
        <copyright>
          <human type="copyright">This work is in the Public Domain.</human>
        </copyright>
        <access type="discover">
          <machine>
            <world/>
          </machine>
        </access>
        <access type="read">
          <machine>
            <group>Berkeley</group>
          </machine>
        </access>
        <use>
          <human type="creativecommons">Attribution Share Alike license</human>
          <machine type="creativecommons">by-sa</machine>
        </use>
      </rightsMetadata>
      XML

      @item = double(Dor::Item)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      # using content metadata, but any datastream would do
      object_rights = double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      allow(@item).to receive(:default_rights).and_return nil
      get 'rights_list', params: { :apo_id => 'abc', :format => :xml }
      expect(response.body.include?('Stanford (APO default)')).to eq(false)
    end

    it 'should show World as the default if discover and read are both world' do
      content = <<-XML
      <?xml version="1.0"?>
      <rightsMetadata>
        <copyright>
          <human type="copyright">This work is in the Public Domain.</human>
        </copyright>
        <access type="discover">
          <machine>
            <world/>
          </machine>
        </access>
        <access type="read">
          <machine>
            <world/>
          </machine>
        </access>
        <use>
          <human type="creativecommons">Attribution Share Alike license</human>
          <machine type="creativecommons">by-sa</machine>
        </use>
      </rightsMetadata>
      XML

      @item = double(Dor::Item)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      # using content metadata, but any datastream would do
      object_rights = double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      allow(@item).to receive(:default_rights).and_return 'world'
      get 'rights_list', params: { :apo_id => 'abc', :format => :xml }
      expect(response.body.include?('World (APO default)')).to eq(true)
    end

    it 'should show Dark as the default if discover and read are both none' do
      content = <<-XML
      <?xml version="1.0"?>
      <rightsMetadata>
        <copyright>
          <human type="copyright">This work is in the Public Domain.</human>
        </copyright>
        <access type="discover">
          <machine>
            <none/>
          </machine>
        </access>
        <access type="read">
          <machine>
            <none/>
          </machine>
        </access>
        <use>
          <human type="creativecommons">Attribution Share Alike license</human>
          <machine type="creativecommons">by-sa</machine>
        </use>
      </rightsMetadata>
      XML

      @item = double(Dor::Item)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      # using content metadata, but any datastream would do
      object_rights = double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      allow(@item).to receive(:default_rights).and_return 'dark'
      get 'rights_list', params: { :apo_id => 'abc', :format => :xml }
      expect(response.body.include?('Dark (Preserve Only) (APO default)')).to eq(true)
    end

    it 'should show Citation Only as the default if discover is world and read is none' do
      content = <<-XML
      <?xml version="1.0"?>
      <rightsMetadata>
        <copyright>
          <human type="copyright">This work is in the Public Domain.</human>
        </copyright>
        <access type="discover">
          <machine>
            <world/>
          </machine>
        </access>
        <access type="read">
          <machine>
            <none/>
          </machine>
        </access>
        <use>
          <human type="creativecommons">Attribution Share Alike license</human>
          <machine type="creativecommons">by-sa</machine>
        </use>
      </rightsMetadata>
      XML

      @item = double(Dor::Item)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      # using content metadata, but any datastream would do
      object_rights = double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      allow(@item).to receive(:default_rights).and_return 'none'
      get 'rights_list', params: { :apo_id => 'abc', :format => :xml }
      expect(response.body.include?('Citation Only (APO default)')).to eq(true)
    end

    it 'should show no default if there is no xml' do
      content = ''
      @item = double(Dor::Item)
      xml = Nokogiri::XML(content)
      allow(Dor).to receive(:find).and_return(@item)
      # using content metadata, but any datastream would do
      object_rights = double(Dor::ContentMetadataDS)
      allow(object_rights).to receive(:ng_xml).and_return xml
      allow(@item).to receive(:defaultObjectRights).and_return object_rights
      allow(@item).to receive(:default_rights).and_return nil
      get 'rights_list', params: { :apo_id => 'abc', :format => :xml }
      expect(response.body.include?('World (APO default)')).to eq(false)
      expect(response.body.include?('Stanford (APO default)')).to eq(false)
      expect(response.body.include?('Citation Only (APO default)')).to eq(false)
      expect(response.body.include?('Dark (Preserve Only) (APO default)')).to eq(false)
    end
  end

  describe 'tracksheet' do
    it 'should generate a tracking sheet with the right default name' do
      get 'tracksheet', params: { :druid => 'xb482bw3979' }
      expect(response.headers['Content-Type']).to eq('pdf; charset=utf-8')
      expect(response.headers['content-disposition']).to eq('attachment; filename=tracksheet-1.pdf')
    end
    it 'should generate a tracking sheet with the specified name (and sequence number)' do
      test_name = 'test_name'
      test_seq_no = 7
      get 'tracksheet', params: { :druid => 'xb482bw3979', :name => test_name, :sequence => test_seq_no }
      expect(response.headers['content-disposition']).to eq("attachment; filename=#{test_name}-#{test_seq_no}.pdf")
    end
  end

  describe '#collection_list' do
    it 'should handle invalid parameters' do
      expect { get 'collection_list' }.to raise_error(ArgumentError)
    end

    it 'should handle a bogus APO' do
      get 'collection_list', params: { apo_id: 'druid:aa111bb2222' }
      expect(response).to have_http_status(:not_found)
    end

    it 'should handle an APO with no collections' do
      get 'collection_list', params: { apo_id: 'druid:zt570tx3016', format: :json }
      data = JSON.parse(response.body)
      expect(data).to include('' => 'None')
      expect(data.length).to eq(1)
    end

    it 'should alpha-sort the collection list by title, except for the "None" entry, which should come first' do
      apo_id = 'druid:fg464dn8891'

      # 'pb873ty1662' is a real object in our fixture data.  for the other two druids, we mock the
      # results of the calls to fedora.  the 'z' druid has a title that should cause it to sort first
      # after "None", and the 'a' druid has a title that should cause it to sort last.
      col_ids_for_apo = ['druid:pb873ty1662', 'druid:ab098cd7654', 'druid:zy123xw4567']
      allow(subject).to receive(:registration_collection_ids_for_apo).with(apo_id).and_return(col_ids_for_apo)
      mock_collection_z = double(Dor::Collection, label: 'A collection that sorts to the top')
      mock_collection_a = double(Dor::Collection, label: 'Ze last collection in ze list')
      allow(Dor).to receive(:find).with('druid:zy123xw4567').and_return(mock_collection_z)
      allow(Dor).to receive(:find).with('druid:pb873ty1662').and_call_original
      allow(Dor).to receive(:find).with('druid:ab098cd7654').and_return(mock_collection_a)

      get 'collection_list', params: { apo_id: apo_id, format: :json }
      data = JSON.parse(response.body)
      expect(data).to eq({
        '' => 'None',
        'druid:zy123xw4567' => 'A collection that sorts to the top (zy123xw4567)',
        'druid:pb873ty1662' => 'Annual report of the State Corporation Commission showing... (pb873ty1662)',
        'druid:ab098cd7654' => 'Ze last collection in ze list (ab098cd7654)'
      })
    end

    it 'should not include collections that are not found in Solr/Fedora' do
      missing_registration_collections = [
        'druid:kk203bw3276', 'druid:zx663qq1749', 'druid:nq832zg5474', 'druid:fb337wh0818', 'druid:kd973gk0505',
        'druid:jm980xw3297', 'druid:fz658ss5788', 'druid:vh782pm7216', 'druid:gg191kg3953'
      ]
      missing_registration_collections.each do |col_id|
        col_not_found_warning = "druid:fg464dn8891 lists collection #{col_id} for registration, but it wasn't found in Fedora."
        expect(Rails.logger).to receive(:warning).with(col_not_found_warning)
      end

      get 'collection_list', params: { apo_id: 'druid:fg464dn8891', format: :json }
      data = JSON.parse(response.body)
      expect(data['druid:pb873ty1662']).to start_with 'Annual report of the State Corporation Commission'
      expect(data['druid:gg191kg3953']).to be nil
      expect(data.length).to eq(2)
    end
  end

  describe '#workflow_list' do
    it 'should handle an APO with a single default workflow' do
      get 'workflow_list', params: { apo_id: 'druid:fg464dn8891', format: :json }
      data = JSON.parse(response.body)
      expect(data).to include 'dpgImageWF'
      expect(data.length).to eq(1)
    end

    it 'should handle an APO with multiple workfllows' do
      get 'workflow_list', params: { apo_id: 'druid:ww057vk7675', format: :json }
      data = JSON.parse(response.body)
      expect(data).to include 'digitizationWF'
      expect(data).to include 'dpgImageWF'
      expect(data).to include 'goobiWF'
      expect(data.length).to eq(3)
      expect(data.sort).to eq(data)
    end
  end

  context '#autocomplete' do
    it 'has no spec yet' do
      skip
    end
  end
end
