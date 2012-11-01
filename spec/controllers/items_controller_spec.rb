require 'spec_helper'
describe ItemsController do
  before :each do
    @item = mock(Dor::Item)
    @current_user=mock(:webauth_user, :login => 'sunetid', :logged_in? => true,:privgroup=>ADMIN_GROUPS.first)
    @current_user.stub(:is_admin).and_return(true)
    ItemsController.any_instance.stub(:current_user).and_return(@current_user)
    Dor::Item.stub(:find).and_return(@item)
  end
  describe "embargo_update" do
    it "should 403 if you arent an admin" do
      @current_user.stub(:is_admin).and_return(false)
      post 'embargo_update', :id => 'oo201oo0001', :date => "12/19/2013"
      response.code.should == "403"
    end
    it "should call Dor::Item.update_embargo" do
      runs=0
      @item.stub(:update_embargo)do |a| 
      runs=1
      true
    end
    post :embargo_update, :id => 'oo201oo0001',:embargo_date => "2012-10-19T00:00:00Z"
    response.code.should == "302"
    runs.should ==1
  end
end
describe "open_version" do
  it 'should call dor-services to open a new version' do
    ran=false
    @item.stub(:open_new_version)do 
    ran=true
  end
  get 'open_version', :item_id => 'oo201oo0001'
  ran.should == true
end 
it 'should 403 if you arent an admin' do
  @current_user.stub(:is_admin).and_return(false)
  get 'open_version', :item_id => 'oo201oo0001'
  response.code.should == "403"
end
end
describe "close_version" do
  it 'should call dor-services to close the version' do
    ran=false
    @item.stub(:close_version)do 
    ran=true
  end
  @item.stub(:current_version).and_return('2')
  get 'close_version', :item_id => 'oo201oo0001'
  ran.should == true
end
it 'should 403 if you arent an admin' do
  @current_user.stub(:is_admin).and_return(false)
  get 'close_version', :item_id => 'oo201oo0001'
  response.code.should == "403"
end
end
describe "add_file" do
  it 'should recieve an uploaded file and add it to the requested resource' do
    pending 'Mock isnt working correctly'
    file=mock(ActionDispatch::Http::UploadedFile)
    ran=false
    @item.stub(:add_file) do
      ran=true
    end
    file.stub(:original_filename).and_return('filename')
    post 'add_file', :uploaded_file => file, :item_id => 'oo201oo0001', :resource => 'resourceID'
    ran.should == true

  end   
  it 'should 403 if you arent an admin' do
    @current_user.stub(:is_admin).and_return(false)
    post 'add_file', :uploaded_file => nil, :item_id => 'oo201oo0001', :resource => 'resourceID'
    response.code.should == "403"
  end     
end
describe "delete_file" do
  it 'should call dor services to remove the file' do
    ran=false
    @item.stub(:remove_file)do 
    ran=true
  end
  get 'delete_file', :item_id => 'oo201oo0001', :file_name => 'old_file'
  ran.should == true
end
it 'should 403 if you arent an admin' do
  @current_user.stub(:is_admin).and_return(false)
  get 'delete_file', :item_id => 'oo201oo0001', :file_name => 'old_file'
  response.code.should == "403"

end

end
describe "replace_file" do
  it 'should recieve an uploaded file and call dor-services' do
    #pending 'Mock isnt working correctly'
    file=mock(ActionDispatch::Http::UploadedFile)
    ran=false
    @item.stub(:replace_file) do
      ran=true
    end
    file.stub(:original_filename).and_return('filename')
    post 'replace_file', :uploaded_file => file, :id => 'oo201oo0001', :resource => 'resourceID', :file_name => 'somefile.txt'
    ran.should == true
  end
  it 'should 403 if you arent an admin' do
    @current_user.stub(:is_admin).and_return(false)
    post 'replace_file', :uploaded_file => nil, :id => 'oo201oo0001', :resource => 'resourceID', :file_name => 'somefile.txt'
    response.code.should == "403"
  end
end
describe "update_parameters" do
  it 'should update the shelve, publish and preserve to yes (used to be true)' do
    contentMD=mock(Dor::ContentMetadataDS)
    @item.stub(:contentMetadata).and_return(contentMD)
    contentMD.stub(:update_attributes) do |file, publish, shelve, preserve|
      shelve.should == "yes"
      preserve.should == "yes"
      publish.should == "yes"
    end
    post 'update_attributes', :shelve => 'on', :publish => 'on', :preserve => 'on', :item_id => 'oo201oo0001', :file_name => 'something.txt'
  end
  it 'should work ok if not all of the values are set' do
    contentMD=mock(Dor::ContentMetadataDS)
    @item.stub(:contentMetadata).and_return(contentMD)
    contentMD.stub(:update_attributes) do |file, publish, shelve, preserve|
      shelve.should == "no"
      preserve.should == "yes"
      publish.should == "yes"
    end
    post 'update_attributes',  :publish => 'on', :preserve => 'on', :item_id => 'oo201oo0001', :file_name => 'something.txt'
  end
  it 'should update the shelve, publish and preserve to no (used to be false)' do
    contentMD=mock(Dor::ContentMetadataDS)
    @item.stub(:contentMetadata).and_return(contentMD)
    contentMD.stub(:update_attributes) do |file, publish, shelve, preserve|
      shelve.should == "no"
      preserve.should == "no"
      publish.should == "no"
    end
    contentMD.should_receive(:update_attributes)
    post 'update_attributes', :shelve => 'no', :publish => 'no', :preserve => 'no', :item_id => 'oo201oo0001', :file_name => 'something.txt'
  end
  it 'should 403 if you arent an admin' do
    @current_user.stub(:is_admin).and_return(false)
    post 'update_attributes', :shelve => 'no', :publish => 'no', :preserve => 'no', :item_id => 'oo201oo0001', :file_name => 'something.txt'
    response.code.should == "403"
  end
end
describe 'get_file' do
  it 'should have dor-services fetch a file from the workspace' do
    @item.stub(:get_file).and_return('abc')
    @item.should_receive(:get_file)
    get 'get_file', :file => 'somefile.txt', :id => 'oo201oo0001'
  end
  it 'should 403 if you arent an admin' do
    @current_user.stub(:is_admin).and_return(false)
    get 'get_file', :file => 'somefile.txt', :id => 'oo201oo0001'
    response.code.should == "403"
  end
end
describe 'datastream_update' do
  it 'should 403 if you arent an admin' do
    @current_user.stub(:is_admin).and_return(false)
    post 'datastream_update', :dsid => 'contentMetadata', :id => 'oo201oo0001', :content => '<contentMetadata/>'
    response.code.should == "403"
  end
  it 'should error on malformed xml' do
    lambda {post 'datastream_update', :dsid => 'contentMetadata', :id => 'oo201oo0001', :content => '<this>isnt well formed.'}.should raise_error
  end
  it 'should call save with good xml' do
    mock_ds=mock(Dor::ContentMetadataDS)
    mock_ds.stub(:content=)
    mock_ds.stub(:save)
    mock_ds.should_receive(:save)
    @item.stub(:datastreams).and_return({'contentMetadata' => mock_ds})
    mock_ds.stub(:dirty?).and_return(false)
    post 'datastream_update', :dsid => 'contentMetadata', :id => 'oo201oo0001', :content => '<contentMetadata><text>hello world</text></contentMetadata>'
  end
end
describe 'resource' do
  it 'should set the object and datastream, then call the view' do
    Dor::Item.should_receive(:find)
    mock_ds=mock(Dor::ContentMetadataDS)
    @item.stub(:datastreams).and_return({'contentMetadata' => mock_ds})
    get 'resource', :item_id => 'oo201oo0001', :resource => '0001'

  end
end
end
