require 'spec_helper'
describe 'apo' do
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
    find_field("title").value.should == "APO Title"
    find_field("copyright").value.should == "Copyright statement"
    find_field("use").value.should == "Use statement"
    find_field("managers").value.should == "dlss:developers"
    find_field("viewers").value.should == "sunetid:someone"
    find_field("desc_md").value.should == 'TEI'
    find_field("collection").value.should == ''
    find_field("cc_license").value.should == "by_sa"
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
    find_field("title").value.should == "New APO Title"
    find_field("copyright").value.should == "New copyright statement"
    find_field("use").value.should == "New use statement"
    find_field("managers").value.should == "dlss:dpg-staff"
    #find_field("viewers").value.should == "sunetid:anyone"
    find_field("desc_md").value.should == 'MODS'
    find_field("collection").value.should == ''
    find_field("cc_license").value.should == "by-nd"
  end
end