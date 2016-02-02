require 'spec_helper'

feature 'APO views' do
  context 'with viewing user' do
    let(:druid) { 'druid:hv992ry2431' }
    let(:item) { instantiate_fixture(druid, Dor::AdminPolicyObject) }
    before :each do
      # use a viewing user that depends on workgroup roles for access
      @view_user = view_user # see spec_helper
      allow(@view_user).to receive(:is_viewer).and_return(false)
      allow(Dor).to receive(:find).with(druid, {}).and_return(item)
    end

    it 'allows a user of an authorized workgroup to view an APO' do
      # Ensure all user authority methods return false and the
      # user belongs to at least one authorized workgroup.
      dor_viewer_roles = %w(dor-viewer sdr-viewer)
      dor_viewer_roles.each do |role|
        allow(@view_user).to receive(:roles).and_return([role])
        allow(item).to receive(:can_view_content?).with([role]).and_return(true)
        visit catalog_path druid
        expect(page).to have_content(druid)
        expect(page).to have_content('adminPolicy')
        # A viewer cannot do admin tasks on the APO, so Argo
        # should not display or activate the Admin links. See
        # ArgoHelper#render_buttons for details.
        apo_admin_links = ['Edit APO', 'Create Collection']
        apo_admin_links.each do |link|
          expect(page.has_link?(link)).to be false
        end
      end
    end

    it 'does not allow any unauthorized user to view an existing APO' do
      # Ensure all user authority methods return false and the
      # user does not belong to any authorized workgroups.
      allow(@view_user).to receive(:roles).and_return([])
      visit catalog_path druid
      expect(page).to have_content('APO forbids access')
    end
  end
end
