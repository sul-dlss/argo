require 'spec_helper'
describe ArgoHelper, :type => :helper do
  describe '#render_buttons' do
    before :each do
      @item_id = 'druid:kv840rx2720'
      @governing_apo_id = 'druid:hv992ry2431'
      @object = instantiate_fixture(@item_id, Dor::Item)
      @doc = SolrDocument.new({'id' => @item_id, SolrDocument::FIELD_APO_ID => [@governing_apo_id]})
      @usr = mock_user(is_admin?: true)
      allow(Dor::Config.workflow.client).to receive(:get_active_lifecycle).and_return(true)
      allow(Dor::Config.workflow.client).to receive(:get_lifecycle).and_return(true)
      allow(controller).to receive(:current_user).and_return(@usr)
      allow(helper).to receive(:current_user).and_return(@usr)
      allow(@object).to receive(:allows_modification?).and_return(true)
      allow(@object).to receive(:pid).and_return(@item_id)
      desc_md = double(Dor::DescMetadataDS)
      @id_md = double(Dor::IdentityMetadataDS)
      governing_apo = double(Dor::AdminPolicyObject)
      allow(desc_md).to receive(:new?).and_return(true)
      allow(@id_md).to receive(:otherId).with('catkey').and_return([])
      allow(@id_md).to receive(:ng_xml).and_return(Nokogiri::XML('<identityMetadata><identityMetadata>'))
      allow(governing_apo).to receive(:pid).and_return(@governing_apo_id)
      # nil datastreams don't need content for these tests, they just need to be present
      datastreams = { 'contentMetadata' => nil, 'rightsMetadata' => nil, 'descMetadata' => desc_md, 'identityMetadata' => @id_md }
      allow(@object).to receive(:datastreams).and_return(datastreams)
      allow(@object).to receive(:admin_policy_object).and_return(governing_apo)
      allow(Dor).to receive(:find).with(@item_id).and_return(@object)
      allow(helper).to receive(:registered_only?).with(@doc).and_return(false)
    end
    context 'a Dor::Item the user can manage, with the usual data streams, and no catkey or embargo info' do
      let(:default_buttons) do
        [
          {
            label: 'Close Version',
            url: "/items/#{@item_id}/close_version_ui",
            check_url: "/workflow_service/#{@item_id}/closeable"
          },
          {
            label: 'Open for modification',
            url: "/items/#{@item_id}/open_version_ui",
            check_url: "/workflow_service/#{@item_id}/openable"
          },
          {
            label: 'Reindex',
            url: "/dor/reindex/#{@item_id}",
            new_page: true
          },
          {
            label: 'Set governing APO',
            url: "/items/#{@item_id}/set_governing_apo_ui",
            disabled: false
          },
          {
            label: 'Add workflow',
            url: "/items/#{@item_id}/add_workflow"
          },
          {
            label: 'Republish',
            url: "/dor/republish/#{@item_id}",
            check_url: "/workflow_service/#{@item_id}/published",
            new_page: true
          },
          {
            label: 'Purge',
            url: "/items/#{@item_id}/purge",
            new_page: true,
            confirm: 'This object will be permanently purged from DOR. This action cannot be undone. Are you sure?',
            disabled: true
          },
          {
            label: 'Change source id',
            url: "/items/#{@item_id}/source_id_ui"
          },
          {
            label: 'Manage catkey',
            url: "/items/#{@item_id}/catkey_ui"
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
          },
          {
            label: 'Set rights',
            url: "/items/#{@item_id}/rights"
          },
          {
            label: 'Manage release',
            url: "/view/#{@item_id}/manage_release"
          }
        ]
      end
      it 'should create a hash with the needed button info for an admin' do
        buttons = helper.render_buttons(@doc)
        default_buttons.each do |button|
          expect(buttons).to include(button)
        end
        expect(buttons.length).to eq default_buttons.length
      end
      it 'should generate the same button set for a non Dor-wide admin with APO specific mgmt privileges' do
        allow(@usr).to receive(:is_admin?).and_return(false)
        allow(@object).to receive(:can_manage_item?).and_return(true)
        allow(@object).to receive(:can_manage_content?).and_return(true)
        buttons = helper.render_buttons(@doc)
        default_buttons.each do |button|
          expect(buttons).to include(button)
        end
        expect(buttons.length).to eq default_buttons.length
      end
      it 'should include the embargo update button if the user is an admin and the object is embargoed' do
        @doc = SolrDocument.new(@doc.to_h.merge('embargo_status_ssim' => ['2012-10-19T00:00:00Z']))
        allow(helper).to receive(:registered_only?).with(@doc).and_return(false)
        buttons = helper.render_buttons(@doc)
        default_buttons.push({
          label: 'Update embargo',
          url: "/items/#{@item_id}/embargo_form"
        }).each do |button|
          expect(buttons).to include(button)
        end
        expect(buttons.length).to eq default_buttons.length
      end
      it "should not generate errors given an object that has no associated APO and a user that can't manage the object" do
        allow(@usr).to receive(:is_admin?).and_return(false)
        allow(@doc).to receive(:apo_pid).and_return(nil)
        allow(@object).to receive(:admin_policy_object).and_return(nil)
        allow(@usr).to receive(:roles).with(nil).and_return([])
        buttons = helper.render_buttons(@doc)
        expect(buttons).not_to be_nil
        expect(buttons.length).to eq 0
      end
      it 'should include the refresh descMetadata button for items with catkey' do
        allow(@id_md).to receive(:otherId).with('catkey').and_return(['1234567'])
        buttons = helper.render_buttons(@doc)
        default_buttons.push({
          label: 'Refresh descMetadata',
          url: "/items/#{@item_id}/refresh_metadata",
          new_page: true,
          disabled: false
        }).each do |button|
          expect(buttons).to include(button)
        end
        expect(buttons.length).to eq default_buttons.length
      end
    end
    context 'a Dor::AdminPolicyObject the user can manage' do
      let(:view_apo_id) { 'druid:zt570tx3016' }
      let(:default_buttons) do
        [
          {
            label: 'Close Version',
            url: "/items/#{view_apo_id}/close_version_ui",
            check_url: "/workflow_service/#{view_apo_id}/closeable"
          },
          {
            label: 'Open for modification',
            url: "/items/#{view_apo_id}/open_version_ui",
            check_url: "/workflow_service/#{view_apo_id}/openable"
          },
          {
            label: 'Edit APO',
            url: "/apo/register?id=#{URI.encode_www_form_component(view_apo_id)}",
            new_page: true
          },
          {
            label: 'Create Collection',
            url: "/apo/#{view_apo_id}/register_collection"
          },
          {
            label: 'Reindex',
            url: "/dor/reindex/#{view_apo_id}",
            new_page: true
          },
          {
            label: 'Set governing APO',
            url: "/items/#{view_apo_id}/set_governing_apo_ui",
            disabled: false
          },
          {
            label: 'Add workflow',
            url: "/items/#{view_apo_id}/add_workflow"
          },
          {
            label: 'Republish',
            url: "/dor/republish/#{view_apo_id}",
            check_url: "/workflow_service/#{view_apo_id}/published",
            new_page: true
          },
          {
            label: 'Purge',
            url: "/items/#{view_apo_id}/purge",
            new_page: true,
            confirm: 'This object will be permanently purged from DOR. This action cannot be undone. Are you sure?',
            disabled: true
          },
          {
            label: 'Change source id',
            url: "/items/#{view_apo_id}/source_id_ui"
          },
          {
            label: 'Edit tags',
            url: "/items/#{view_apo_id}/tags_ui"
          },
          {
            label: 'Set rights',
            url: "/items/#{view_apo_id}/rights"
          },
          {
            label: 'Manage release',
            url: "/view/#{view_apo_id}/manage_release"
          }
        ]
      end
      it 'renders the appropriate default buttons for an apo' do
        @object = instantiate_fixture(view_apo_id, Dor::AdminPolicyObject)
        @doc = SolrDocument.new({'id' => view_apo_id, SolrDocument::FIELD_APO_ID => [@governing_apo_id]})
        allow(Dor).to receive(:find).with(view_apo_id).and_return(@object)
        allow(helper).to receive(:registered_only?).with(@doc).and_return(false)
        buttons = helper.render_buttons(@doc)
        default_buttons.each do |button|
          expect(buttons).to include(button)
        end
        expect(buttons.length).to eq default_buttons.length
      end
    end
  end
  describe 'render_facet_value' do
    it 'should not override Blacklight version' do
      expect(helper.respond_to?(:render_facet_value)).to be_truthy
      expect(helper.method(:render_facet_value).owner).to eq(Blacklight::FacetsHelperBehavior)
    end
  end
  describe '#registered_only?' do
    it 'returns true for registered only item' do
      expect(helper.registered_only?({ 'processing_status_text_ssi' => 'Registered' })).to eq true
      expect(helper.registered_only?({ 'processing_status_text_ssi' => 'Unknown Status' })).to eq true
    end
    it 'returns false for items beyond registered only' do
      expect(helper.registered_only?({ 'processing_status_text_ssi' => 'In accessioning' })).to eq false
    end
  end
end
