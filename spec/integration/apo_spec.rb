require 'spec_helper'
describe 'apo', :type => :request do
  before :each do
    pending
  end
  it 'should register an apo' do
    log_in_as_mock_user(subject)
    #go to the registration form and fill it in
    visit url_for(:controller => :apo, :action => :register)
    fill_in "title",    :with => 'APO Title'
    fill_in "copyright", :with => 'Copyright statement'
    fill_in "use", :with => "Use statement"
    page.select("TEI", :from => "desc_md")
    page.select("None", :from => "collection")
    page.select("Attribution Share Alike 3.0 Unported", :from => "cc_license")
    fill_in "managers", :with => 'dlss:developers'
    fill_in 'viewers', :with => 'sunetid:someone'
    click_button "register"
    #look at the redirect path to find the new druid
    druid=current_path.split('/').last
    visit url_for(:controller => :apo, :action => :register, :id => druid)
    #check the edit form to see that all of the filled in values match what was put in at registration time
    expect(find_field("title").value).to eq("APO Title")
    expect(find_field("copyright").value).to eq("Copyright statement")
    expect(find_field("use").value).to eq("Use statement")
    expect(find_field("managers").value).to eq("dlss:developers")
    expect(find_field("viewers").value).to eq("sunetid:someone")
    expect(find_field("desc_md").value).to eq('TEI')
    expect(find_field("collection").value).to eq('')
    expect(find_field("cc_license").value).to eq("by_sa")
  end
  it 'should edit an apo' do
    log_in_as_mock_user(subject)
    #go to the registration form and fill it in
    visit url_for(:controller => :apo, :action => :register)
    fill_in "title",    :with => 'APO Title'
    fill_in "copyright", :with => 'Copyright statement'
    fill_in "use", :with => "Use statement"
    page.select("TEI", :from => "desc_md")
    page.select("None", :from => "collection")
    page.select("Attribution Share Alike 3.0 Unported", :from => "cc_license")
    fill_in "managers", :with => 'dlss:developers dlss:psm-staff'
    fill_in 'viewers', :with => 'sunetid:someone'
    click_button "register"
    #look at the redirect path to find the new druid
    druid=current_path.split('/').last
    visit url_for(:controller => :apo, :action => :register, :id => druid)
    #now modify it.
    fill_in "title",    :with => 'New APO Title'
    fill_in "copyright", :with => 'New copyright statement'
    fill_in "use", :with => "New use statement"
    page.select("MODS", :from => "desc_md")
    page.select("None", :from => "collection")
    page.select("Attribution No Derivatives 3.0 Unported", :from => "cc_license")
    fill_in "managers", :with => 'dlss:dpg-staff'
    fill_in 'viewers', :with => 'sunetid:anyone'
    click_button "register"
    visit url_for(:controller => :apo, :action => :register, :id => druid)
    expect(find_field("title").value).to eq("New APO Title")
    expect(find_field("copyright").value).to eq("New copyright statement")
    expect(find_field("use").value).to eq("New use statement")
    expect(find_field("managers").value).to eq("dlss:dpg-staff")
    #find_field("viewers").value.should == "sunetid:anyone"
    expect(find_field("desc_md").value).to eq('MODS')
    expect(find_field("collection").value).to eq('')
    expect(find_field("cc_license").value).to eq("by-nd")
  end
end