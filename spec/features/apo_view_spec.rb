require 'spec_helper'

feature 'APO views' do
  context 'with viewing user' do
    let(:apo) do
      object = instantiate_fixture('hv992ry2431', Dor::AdminPolicyObject)
      allow(Dor).to receive(:find).with(object.pid).and_return(object)
      object
    end
    let(:current_user) do
      # To ensure all Argo user authority methods return false and the
      # user does not belong to any authorized workgroups, use a
      # view_user that depends on workgroup roles for access.
      user = view_user # see spec_helper
      allow(user).to receive(:is_viewer).and_return(false)
      user
    end

    it 'allows a user of an authorized workgroup to view an APO' do
      viewer_roles = %w(sdr-viewer)
      viewer_roles.each do |role|
        expect(current_user).to receive(:roles).at_least(:once).and_return([role])
        expect(apo).to receive(:can_view_metadata?).with([role]).at_least(:once).and_return(true)
        visit catalog_path apo.pid
        expect(page).to have_content(apo.pid)
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

    it 'does not allow a user of an obsolete workgroup to view an existing APO' do
      viewer_roles = %w(dor-viewer)
      viewer_roles.each do |role|
        expect(current_user).to receive(:roles).with(apo.pid).at_least(:once).and_return([role])
        expect(apo).to receive(:can_view_metadata?).with([role]).at_least(:once).and_return(false)
        visit catalog_path apo.pid
        expect(page).to have_content('APO forbids access')
      end
    end

    it 'does not allow any unauthorized user to view an existing APO' do
      expect(current_user).to receive(:roles).at_least(:once).and_return([])
      visit catalog_path apo.pid
      expect(page).to have_content('APO forbids access')
    end
  end
end
