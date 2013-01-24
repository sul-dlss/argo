require 'spec_helper'
describe ItemsController do
  before :each do
    #TODO use fixtures here, this is too much stubbing
    @item = mock(Dor::Item)
    @item.stub(:to_solr)
    @current_user=mock(:webauth_user, :login => 'sunetid', :logged_in? => true,:privgroup=>ADMIN_GROUPS.first)
    @current_user.stub(:is_admin).and_return(true)
    @current_user.stub(:roles).and_return([])
    @current_user.stub(:is_manager).and_return(false)
    ItemsController.any_instance.stub(:current_user).and_return(@current_user)
    Dor::Item.stub(:find).and_return(@item)
    @event_ds=mock(Dor::EventsDS)
    @event_ds.stub(:add_event)
    @ds={}
    idmd=mock()
    idmd.stub(:dirty=)
    @item.stub(:save)
    @ds['identityMetadata']=idmd
    @item.stub(:identityMetadata).and_return(idmd)
    @ds['events'] = @event_ds
    @item.stub(:datastreams).and_return(@ds)
    @item.stub(:can_manage_item?).and_return(false)
    @item.stub(:can_manage_content?).and_return(false)
    @item.stub(:can_view_content?).and_return(false)
    apo=mock
    apo.stub(:pid).and_return('druid:ab12cde7890')
    @item.stub(:admin_policy_object).and_return([apo])
    Dor::SearchService.solr.stub(:add)
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
  version_metadata=mock(Dor::VersionMetadataDS)
  version_metadata.stub(:current_version_id).and_return(2)
  version_metadata.should_receive(:update_current_version)
  @item.stub(:versionMetadata).and_return(version_metadata)
  @item.stub(:current_version).and_return('2')
  @item.stub(:save)
  get 'open_version', :id => 'oo201oo0001', :severity => 'major', :description => 'something'
  ran.should == true
end 
it 'should 403 if you arent an admin' do
  @current_user.stub(:is_admin).and_return(false)
  get 'open_version', :id => 'oo201oo0001', :severity => 'major', :description => 'something'
  response.code.should == "403"
end
end
describe "close_version" do
  it 'should call dor-services to close the version' do
    ran=false
    @item.stub(:close_version)do 
    ran=true
  end
  version_metadata=mock(Dor::VersionMetadataDS)
  version_metadata.stub(:current_version_id).and_return(2)
  @item.stub(:versionMetadata).and_return(version_metadata)
  version_metadata.should_receive(:update_current_version)
  @item.stub(:current_version).and_return('2')
  @item.stub(:save)
  get 'close_version', :id => 'oo201oo0001', :severity => 'major', :description => 'something'
  ran.should == true
end
it 'should 403 if you arent an admin' do
  @current_user.stub(:is_admin).and_return(false)
  get 'close_version', :item_id => 'oo201oo0001'
  response.code.should == "403"
end
end
describe "source_id" do
  it 'should update the source id' do
    @item.should_receive(:set_source_id).with('new source id')
    post 'source_id', :id => 'oo201oo0001', :new_id => 'new source id'
  end
end
describe "tags" do
  before :each do
    @item.stub(:tags).and_return(['some:thing'])
  end
  it 'should update tags' do
    @item.should_receive(:update_tag).with('some:thing', 'some:thingelse')
    post 'tags', :id => 'oo201oo0001', :update=>'true', :tag1 => 'some:thingelse'
  end
  it 'should delete tag' do
    @item.should_receive(:remove_tag).with('some:thing').and_return(true)
    post 'tags', :id => 'oo201oo0001', :tag => '1', :del => 'true'
  end
  it 'should add a tag' do
    @item.should_receive(:add_tag).with('new:thing')
    post 'tags', :id => 'oo201oo0001', :new_tag1 => 'new:thing', :add => 'true'
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
describe 'update_sequence' do
  it 'should 403 if you arent an admin' do
    @current_user.stub(:is_admin).and_return(false)
    post 'update_resource', :resource => '0001', :position => '3', :item_id => 'oo201oo0001'
    response.code.should == "403"
  end
  it 'should call dor-services to reorder the resources' do
    mock_ds=mock(Dor::ContentMetadataDS)
    @item.stub(:move_resource)
    @item.should_receive(:move_resource)
    mock_ds.stub(:save)
    @item.stub(:datastreams).and_return({'contentMetadata' => mock_ds})
    mock_ds.stub(:dirty?).and_return(false)
    post 'update_resource', :resource => '0001', :position => '3', :item_id => 'oo201oo0001'
  end
  it 'should call dor-services to change the label' do
    mock_ds=mock(Dor::ContentMetadataDS)
    @item.stub(:update_resource_label)
    @item.should_receive(:update_resource_label)
    mock_ds.stub(:save)
    @item.stub(:datastreams).and_return({'contentMetadata' => mock_ds})
    mock_ds.stub(:dirty?).and_return(false)
    post 'update_resource', :resource => '0001', :label => 'label!', :item_id => 'oo201oo0001'
  end
  it 'should call dor-services to update the resource type' do
    mock_ds=mock(Dor::ContentMetadataDS)
    @item.stub(:update_resource_type)
    @item.should_receive(:update_resource_type)
    mock_ds.stub(:save)
    @item.stub(:datastreams).and_return({'contentMetadata' => mock_ds})
    mock_ds.stub(:dirty?).and_return(false)
    post 'update_resource', :resource => '0001', :type => 'book', :item_id => 'oo201oo0001'
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
