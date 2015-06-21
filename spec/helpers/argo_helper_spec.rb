require 'spec_helper'
describe ArgoHelper, :type => :helper do
  describe 'render_document_show_thumbnail' do
    it 'should include a thumbnail url' do
      doc={'first_shelved_image_display'=>['testimage.jp2']}
      expect(helper.render_document_show_thumbnail(doc)  ).to  \
        match(/src=".*testimage_thumb"/                  ).and \
        match(/style="max-width:240px;max-height:240px;"/).and \
        match(/alt=""/)
    end
  end
  describe 'render_index_thumbnail' do
    it 'should include a thumbnail url' do
      doc={'first_shelved_image_display'=>['testimage.jp2']}
      expect(helper.render_document_show_thumbnail(doc)  ).to  \
        match(/src=".*testimage_thumb"/                  ).and \
        match(/style="max-width:240px;max-height:240px;"/).and \
        match(/alt=""/)
    end
  end
  describe 'render_buttons' do
    before :each do
      @object = instantiate_fixture("druid_zt570tx3016", Dor::Item)
      @doc={'id'=>'something', 'is_governed_by_ssim'=>['apo_druid']}
      @usr=double()
      allow(@usr).to receive(:is_admin).and_return(true)
      allow(@usr).to receive(:groups).and_return([])
      allow(@usr).to receive(:is_manager).and_return(false)
      allow(Dor::WorkflowService).to receive(:get_active_lifecycle).and_return(true)
      allow(Dor::WorkflowService).to receive(:get_lifecycle).and_return(true)
      allow(helper).to receive(:has_been_published?).and_return(true)
      allow(helper).to receive(:current_user).and_return(@usr)
      allow(@object).to receive(:can_manage_item?).and_return(true)
      allow(@object).to receive(:pid).and_return('druid:123')
      descMD=double(Dor::DescMetadataDS)
      allow(descMD).to receive(:new?).and_return(true)
      idMD=double(Dor::DescMetadataDS)
      allow(idMD).to receive(:ng_xml).and_return(Nokogiri::XML('<identityMetadata><identityMetadata>'))
      allow(@object).to receive(:datastreams).and_return({'contentMetadata'=>nil, 'descMetadata' => descMD, 'identityMetadata' => idMD})
      @apo=double()
      allow(@usr).to receive(:roles).with('apo_druid').and_return([])
      allow(@apo).to receive(:pid).and_return('apo:druid')
      allow(@object).to receive(:admin_policy_object).and_return(@apo)
      allow(Dor).to receive(:find).and_return(@object)
    end
    it 'should create a hash with the needed button info for an admin' do
      buttons = helper.render_buttons(@doc)
      {
        'Reindex'           => '/dor/reindex/something',
        'Republish'         => '/dor/republish/something',
        'Change source id'  => '/items/something/source_id_ui',
        'Edit tags'         => '/items/something/tags_ui',
        'Edit collections'  => '/items/something/collection_ui',
        'Set content type'  => '/items/something/content_type',
      }.each_pair do |k,v|
        expect(buttons.include?({:label=>k,:url=>v})).to be_truthy
      end
    end
    it 'should generate a the same button set for a non admin' do
      allow(@usr).to receive(:is_admin).and_return(false)
      allow(@object).to receive(:can_manage_item?).and_return(true)
      buttons = helper.render_buttons(@doc)
      {
        'Reindex'           => '/dor/reindex/something',
        'Republish'         => '/dor/republish/something',
        'Change source id'  => '/items/something/source_id_ui',
        'Edit tags'         => '/items/something/tags_ui',
        'Edit collections'  => '/items/something/collection_ui',
        'Set content type'  => '/items/something/content_type',
      }.each_pair do |k,v|
        expect(buttons.include?({:label=>k,:url=>v})).to be_truthy
      end
    end
    it 'should include the embargo update button if the user is an admin and the object is embargoed' do
      @doc['embargoMetadata_t'] = ['2012-10-19T00:00:00Z']
      buttons = helper.render_buttons(@doc)
      {
        'Reindex'           => '/dor/reindex/something',
        'Republish'         => '/dor/republish/something',
        'Change source id'  => '/items/something/source_id_ui',
        'Edit tags'         => '/items/something/tags_ui',
        'Edit collections'  => '/items/something/collection_ui',
        'Set content type'  => '/items/something/content_type',
        'Update embargo'    => '/items/something/embargo_form',
      }.each_pair do |k,v|
        expect(buttons.include?({:label=>k,:url=>v})).to be_truthy
      end
    end
    it 'should inlcude the edit MODS button if there is a desc metadata ds in fedora' do
      @item = instantiate_fixture("druid_zt570tx3016", Dor::AdminPolicyObject)
      allow(@item.descMetadata).to receive(:new?).and_return(false)
      allow(@item.datastreams['descMetadata']).to receive(:new?).and_return(false)
      allow(Dor).to receive(:find).and_return(@item)
      expect(@item.identityMetadata).to receive(:otherId).and_return([],[])
      expect(helper.render_buttons(@doc).include?({:url=>"/items/something/mods", :label=>"Edit MODS", :new_page=>true})).to be_truthy
    end
    it 'should exclude the edit mods button if the item has a catkey in otherids, meaning it uses symphony as its metadata source' do
      @item = instantiate_fixture("druid_zt570tx3016", Dor::AdminPolicyObject)
      allow(@item.descMetadata).to receive(:new?).and_return(false)
      allow(@item.datastreams['descMetadata']).to receive(:new?).and_return(false)
      allow(Dor).to receive(:find).and_return(@item)
      expect(@item.identityMetadata).to receive(:otherId).and_return(['a1234567'])
      expect(helper.render_buttons(@doc).include?({:url=>"/items/something/mods", :label=>"Edit MODS", :new_page=>true})).to eq(false)
    end
    it 'should exclude the edit mods button if the item has a mdtoolkit value in otherids, meaning it uses mdtoolkit as its metadata source' do
      @item = instantiate_fixture("druid_zt570tx3016", Dor::AdminPolicyObject)
      expect(@item.identityMetadata).to receive(:otherId).and_return([],['a1234567'])
      allow(@item.datastreams['descMetadata']).to receive(:new?).and_return(false)
      allow(Dor).to receive(:find).and_return(@item)
      expect(helper.render_buttons(@doc).include?({:url=>"/items/something/mods", :label=>"Edit MODS", :new_page=>true})).to be_falsey
    end
  end
end
