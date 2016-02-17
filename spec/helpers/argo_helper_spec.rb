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
      @item = instantiate_fixture('druid_zt570tx3016', Dor::Item)
      allow(Dor).to receive(:find).with(@item.pid).and_return(@item)
      allow(@item).to receive(:can_manage_item?).and_return(true)

      @apo = @item.admin_policy_object
      @doc = SolrDocument.new({'id' => @item.pid, SolrDocument::FIELD_APO_ID => [@apo.pid]})

      desc_md = double(Dor::DescMetadataDS)
      allow(desc_md).to receive(:new?).and_return(true)
      id_md = double(Dor::DescMetadataDS)
      allow(id_md).to receive(:ng_xml).and_return(Nokogiri::XML('<identityMetadata><identityMetadata>'))
      allow(@item).to receive(:datastreams).and_return({
        'contentMetadata' => nil,
        'descMetadata' => desc_md,
        'identityMetadata' => id_md
      })

      allow(Dor::WorkflowService).to receive(:get_active_lifecycle).and_return(true)
      allow(Dor::WorkflowService).to receive(:get_lifecycle).and_return(true)

      @usr = double()
      allow(@usr).to receive(:is_admin).and_return(true)
      allow(@usr).to receive(:is_manager).and_return(false)
      allow(@usr).to receive(:groups).and_return([])
      allow(@usr).to receive(:roles).with(@apo.pid).and_return([])
      allow(helper).to receive(:current_user).and_return(@usr)
    end
    describe 'visibility with new descMetadata' do
      let(:default_buttons) do
        [
          {
            label: 'Reindex',
            url: "/dor/reindex/#{@item.pid}",
            new_page: true
          },
          {
            label: 'Republish',
            url: "/dor/republish/#{@item.pid}",
            check_url: "/workflow_service/#{@item.pid}/published",
            new_page: true
          },
          {
            label: 'Change source id',
            url: "/items/#{@item.pid}/source_id_ui"
          },
          {
            label: 'Edit tags',
            url: "/items/#{@item.pid}/tags_ui"
          },
          {
            label: 'Edit collections',
            url: "/items/#{@item.pid}/collection_ui"
          },
          {
            label: 'Set content type',
            url: "/items/#{@item.pid}/content_type"
          }
        ]
      end
      it 'should create a hash with the needed button info for an admin' do
        allow(@item).to receive(:can_manage_item?).and_return(false)
        expect(@usr).to receive(:is_admin).at_least(:once)
        buttons = helper.render_buttons(@doc)
        default_buttons.each do |button|
          expect(buttons).to include(button)
        end
      end
      it 'should generate the same button set for a non admin' do
        allow(@usr).to receive(:is_admin).and_return(false)
        allow(@usr).to receive(:is_manager).and_return(false)
        expect(@usr).to receive(:roles).at_least(:once)
        expect(@item).to receive(:can_manage_item?).at_least(:once).and_return(true)
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
          url: "/items/#{@item.pid}/embargo_form"
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
end
