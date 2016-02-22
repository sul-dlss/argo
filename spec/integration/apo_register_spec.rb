require 'spec_helper'

describe 'apo', :type => :request do
  def create_apo(druid)
    expect(Dor::SuriService).to receive(:mint_id).and_return(druid)
    expect(Dor::WorkflowService).to receive(:create_workflow)
    # go to the registration form and fill it in
    visit '/apo/register'
    fill_in 'title', :with => 'APO Title'
    fill_in 'copyright', :with => 'Copyright statement'
    fill_in 'use', :with => 'Use statement'
    fill_in 'managers', :with => 'dlss:developers'
    fill_in 'viewers', :with => 'sunetid:someone'
    page.select('TEI', :from => 'desc_md')
    page.select('Attribution Share Alike 3.0 Unported', :from => 'use_license')
    choose('collection_radio', option: 'none')
    click_button 'register'
    expect{Dor.find(druid)}.not_to raise_error
  end

  def destroy_druid(druid)
    Dor.find(druid).destroy
  rescue ActiveFedora::ObjectNotFoundError
    nil
  end

  context 'with admin user' do
    before :each do
      admin_user # from spec_helper
    end
    after :each do
      destroy_druid @druid
    end

    it 'should register an apo' do
      @druid = 'druid:zy987wv6543'
      create_apo @druid
      # button redirects to catalog view, but return to edit form to check registered values
      visit url_for(:controller => :apo, :action => :register, :id => @druid)
      expect(find_field('title').value).to eq('APO Title')
      expect(find_field('copyright').value).to eq('Copyright statement')
      expect(find_field('use').value).to eq('Use statement')
      expect(find_field('managers').value).to eq('dlss:developers')
      expect(find_field('viewers').value).to eq('sunetid:someone')
      expect(find_field('desc_md').value).to eq('TEI')
      expect(find_field('use_license').value).to eq('by-sa')
      expect(page).to have_no_field('collection')
    end

    it 'should edit an existing apo' do
      @druid = 'druid:ab987cd6543'
      create_apo @druid
      visit url_for(:controller => :apo, :action => :register, :id => @druid)
      fill_in 'managers', :with => 'dlss:developers dlss:psm-staff'
      fill_in 'viewers', :with => 'sunetid:someone'
      fill_in 'title', :with => 'New APO Title'
      fill_in 'copyright', :with => 'New copyright statement'
      fill_in 'use', :with => 'New use statement'
      fill_in 'managers', :with => 'dlss:dpg-staff'
      fill_in 'viewers', :with => 'sunetid:anyone'
      page.select('Attribution No Derivatives 3.0 Unported', :from => 'use_license')
      page.select('MODS', :from => 'desc_md')
      click_button 'register'
      visit url_for(:controller => :apo, :action => :register, :id => @druid)
      expect(find_field('title').value).to eq('New APO Title')
      expect(find_field('copyright').value).to eq('New copyright statement')
      expect(find_field('use').value).to eq('New use statement')
      expect(find_field('managers').value).to eq('dlss:dpg-staff')
      expect(find_field('viewers').value).to eq('sunetid:anyone')
      expect(find_field('desc_md').value).to eq('MODS')
      expect(find_field('use_license').value).to eq('by-nd')
      expect(page).to have_no_field('collection')
    end
  end # with admin user
end
