require 'spec_helper'
describe ArgoHelper, :type => :helper do
  describe 'render_document_show_thumbnail' do
    it 'should include a thumbnail url' do
      doc = {'first_shelved_image_ss' => 'testimage.jp2'}
      expect(helper.render_document_show_thumbnail(doc)            ).to  \
        match(%r{src=".*testimage\/full\/!400,400\/0\/default.jpg"}).and \
        match(/style="max-width:240px;max-height:240px;"/          ).and \
        match(/alt=""/)
    end
  end
  describe 'render_index_thumbnail' do
    it 'should include a thumbnail url' do
      doc = {'first_shelved_image_ss' => 'testimage.jp2'}
      expect(helper.render_index_thumbnail(doc)                    ).to  \
        match(%r{src=".*testimage\/full\/!400,400\/0\/default.jpg"}).and \
        match(/style="max-width:240px;max-height:240px;"/          ).and \
        match(/alt=""/)
    end
  end
  describe 'render_buttons' do
    before :each do
      @item_id = 'druid:zt570tx3016'
      @apo_id = 'druid:hv992ry2431'
      @object = instantiate_fixture('druid_zt570tx3016', Dor::Item)
      @doc = SolrDocument.new({'id' => @item_id, SolrDocument::FIELD_APO_ID => [@apo_id]})
      @usr = mock_user(is_admin?: true)
      allow(Dor::Config.workflow.client).to receive(:get_active_lifecycle).and_return(true)
      allow(Dor::Config.workflow.client).to receive(:get_lifecycle).and_return(true)
      allow(helper).to receive(:current_user).and_return(@usr)
      allow(@object).to receive(:can_manage_item?).and_return(true)
      allow(@object).to receive(:pid).and_return(@item_id)
      desc_md = double(Dor::DescMetadataDS)
      id_md   = double(Dor::DescMetadataDS)
      apo     = double()
      allow(desc_md).to receive(:new?).and_return(true)
      allow(id_md).to receive(:ng_xml).and_return(Nokogiri::XML('<identityMetadata><identityMetadata>'))
      allow(apo).to receive(:pid).and_return(@apo_id)
      allow(@object).to receive(:datastreams).and_return({'contentMetadata' => nil, 'descMetadata' => desc_md, 'identityMetadata' => id_md})
      allow(@object).to receive(:admin_policy_object).and_return(apo)
      allow(Dor).to receive(:find).with(@item_id).and_return(@object)
    end
    describe 'visibility with new descMetadata' do
      let(:default_buttons) do
        [
          {
            label: 'Reindex',
            url: "/dor/reindex/#{@item_id}",
            new_page: true
          },
          {
            label: 'Republish',
            url: "/dor/republish/#{@item_id}",
            check_url: "/workflow_service/#{@item_id}/published",
            new_page: true
          },
          {
            label: 'Change source id',
            url: "/items/#{@item_id}/source_id_ui"
          },
          {
            label: 'Edit tags',
            url: "/items/#{@item_id}/tags_ui"
          },
          {
            label: 'Edit collections',
            url: "/items/#{@item_id}/collection_ui"
          },
          {
            label: 'Set content type',
            url: "/items/#{@item_id}/content_type"
          }
        ]
      end
      it 'should create a hash with the needed button info for an admin' do
        buttons = helper.render_buttons(@doc)
        default_buttons.each do |button|
          expect(buttons).to include(button)
        end
      end
      it 'should generate a the same button set for a non admin' do
        allow(@usr).to receive(:is_admin?).and_return(false)
        allow(@object).to receive(:can_manage_item?).and_return(true)
        buttons = helper.render_buttons(@doc)
        default_buttons.each do |button|
          expect(buttons).to include(button)
        end
      end
      it 'should include the embargo update button if the user is an admin and the object is embargoed' do
        @doc['embargo_status_ssim'] = ['2012-10-19T00:00:00Z']
        buttons = helper.render_buttons(@doc)
        default_buttons.push({
          label: 'Update embargo',
          url: "/items/#{@item_id}/embargo_form"
        }).each do |button|
          expect(buttons).to include(button)
        end
      end
      it 'should not generate errors given an object that has no associated APO' do
        allow(@doc).to receive(:apo_pid).and_return(nil)
        allow(@usr).to receive(:roles).with(nil).and_return([])
        buttons = helper.render_buttons(@doc)
        expect(buttons).not_to be_nil
        expect(buttons.length).to be > 0
      end
    end
  end
  describe 'render_facet_value' do
    it 'should not override Blacklight version' do
      expect(helper.respond_to?(:render_facet_value)).to be_truthy
      expect(helper.method(:render_facet_value).owner).to eq(Blacklight::FacetsHelperBehavior)
    end
  end
  describe 'purge button' do
    it 'is enabled for registered only item' do
      expect(helper.registered_only?({ 'processing_status_text_ssi' => 'Registered'})).to be_truthy
      expect(helper.registered_only?({ 'processing_status_text_ssi' => 'Unknown Status'})).to be_truthy
    end
    it 'is disabled for items beyond registered only' do
      expect(helper.registered_only?({ 'processing_status_text_ssi' => 'In accessioning'})).to be_falsey
    end
  end
end
