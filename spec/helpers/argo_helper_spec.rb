require 'spec_helper'
describe ArgoHelper do
	describe 'render_document_show_thumbnail' do
		it 'should include a thumbnail url' do
			doc={'first_shelved_image_display'=>['testimage.jp2']}
			link=helper.render_document_show_thumbnail(doc)
			#alt is blank, points to thumb rather than fixed 240x240
			link.should match 'testimage_thumb" style="max-width:240px;max-height:240px;" />'
		end
	end
	describe 'render_index_thumbnail' do
		it 'should include a thumbnail url' do
			doc={'first_shelved_image_display'=>['testimage.jp2']}
			link=helper.render_index_thumbnail(doc)
			#alt is blank, points to thumb rather than fixed sie 80x80 or 240x240
			link.should match 'testimage_thumb" style="max-width:80px;max-height:80px;" />'
		end
	end
	describe 'render_buttons' do
    before :each do
      @object = instantiate_fixture("druid_zt570tx3016", Dor::Item)
      @doc={'id'=>'something', 'is_governed_by_s'=>['apo_druid']}
      @usr=mock()
      @usr.stub(:is_admin).and_return(true)
      @usr.stub(:groups).and_return([])
      @usr.stub(:is_manager).and_return(false)
      Dor::WorkflowService.stub(:get_active_lifecycle).and_return(true)
      Dor::WorkflowService.stub(:get_lifecycle).and_return(true)
      helper.stub(:has_been_published?).and_return(true)
      helper.stub(:current_user).and_return(@usr)
      @object.stub(:can_manage_item?).and_return(true)
      @object.stub(:pid).and_return('druid:123')
      descMD=mock(Dor::DescMetadataDS)
      descMD.stub(:new?).and_return(true)
      @object.stub(:datastreams).and_return({'contentMetadata'=>nil, 'descMetadata' => descMD})
      @apo=mock()
      @usr.should_receive(:roles).with('apo_druid').and_return([])
      @apo.stub(:pid).and_return('apo:druid')
      @object.stub(:admin_policy_object).and_return(@apo)
      Dor.stub(:find).and_return(@object)
    end
    it 'should create a hash with the needed button info for an admin' do
       helper.render_buttons(@doc).should == [{:label=>"Reindex", :url=>"/dor/reindex/something"},
         {:label=>"Republish", :url=>"/dor/republish/something"},
         {:label=>"Change source id", :url=>"/items/something/source_id_ui"},
         {:label=>"Edit tags", :url=>"/items/something/tags_ui"},
         {:label=>"Edit collections", :url=>"/items/something/collection_ui"},
         {:label=>"Set content type", :url=>"/items/something/content_type"}]
    end
    it 'should generate a the same button set for a non admin' do
      @usr.stub(:is_admin).and_return(false)
      @object.stub(:can_manage_item?).and_return(true)
      helper.render_buttons(@doc).should == [{:label=>"Reindex", :url=>"/dor/reindex/something"},
         {:label=>"Republish", :url=>"/dor/republish/something"},
         {:label=>"Change source id", :url=>"/items/something/source_id_ui"},
         {:label=>"Edit tags", :url=>"/items/something/tags_ui"},
         {:label=>"Edit collections", :url=>"/items/something/collection_ui"},
         {:label=>"Set content type", :url=>"/items/something/content_type"}]
       end
    it 'should include the embargo update button if the user is an admin and the object is embargoed' do
      @doc['embargoMetadata_t'] = ['2012-10-19T00:00:00Z']
      helper.render_buttons(@doc).should == [{:label=>"Reindex", :url=>"/dor/reindex/something"},
         {:label=>"Republish", :url=>"/dor/republish/something"},
         {:label=>"Change source id", :url=>"/items/something/source_id_ui"},
         {:label=>"Edit tags", :url=>"/items/something/tags_ui"},
         {:label=>"Edit collections", :url=>"/items/something/collection_ui"},
         {:label=>"Set content type", :url=>"/items/something/content_type"},
         {:label=>"Update embargo", :url=>"items/embargo_form"}]
    end
    it 'should inlcude the edit MODS button if there is a desc metadata ds in fedora' do
      descMD=mock(Dor::DescMetadataDS)
      descMD.stub(:new?).and_return(false)
      @object.stub(:datastreams).and_return({'contentMetadata'=>nil, 'descMetadata' => descMD})
      helper.render_buttons(@doc).should == [{:label=>"Reindex", :url=>"/dor/reindex/something"},
        {:label=>"Republish", :url=>"/dor/republish/something"},
        {:label=>"Change source id", :url=>"/items/something/source_id_ui"},
        {:label=>"Edit tags", :url=>"/items/something/tags_ui"},
        {:label=>"Edit collections", :url=>"/items/something/collection_ui"},
        {:label=>"Set content type", :url=>"/items/something/content_type"},
        {:url=>"/items/something/mods", :label=>"Edit MODS", :new_page=>true}]
    end
  end
end