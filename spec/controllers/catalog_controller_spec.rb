require 'spec_helper'

describe CatalogController, :type => :controller do

  before :each do
#   log_in_as_mock_user(subject)
    @druid = 'rn653dy9317'  # a fixture Dor::Item record
    @item = instantiate_fixture(@druid, Dor::Item)
    @user = double(User, :login => 'sunetid', :logged_in? => true, :is_admin => false, :is_viewer => false)
    allow(Dor).to receive(:find).with("druid:#{@druid}").and_return(@item)
    allow(Dor::Item).to receive(:find).with("druid:#{@druid}").and_return(@item)
  end

  describe "show enforces permissions" do
    describe "without APO" do
      before :each do
        allow(@item).to receive(:admin_policy_object).and_return(nil)
      end
      describe "no user" do
        it "basic get redirects to login" do
          expect(subject).to receive(:webauth).and_return(nil)
          get 'show', :id => @druid
          expect(response.code).to eq("302")  # redirect for auth
        end
      end
      describe "with user" do
        before :each do
          allow(subject).to receive(:current_user).and_return(@user)
        end
        it "unauthorized_user" do
          get 'show', :id => @druid
          expect(response.code).to eq("403")  # Forbidden
          expect(response.body).to include 'No APO'
        end
        it "is_admin" do
          allow(@user).to receive(:is_admin).and_return(true)
          get 'show', :id => @druid
          expect(response.code).to eq("200")
        end
        it "is_viewer" do
          allow(@user).to receive(:is_viewer).and_return(true)
          get 'show', :id => @druid
          expect(response.code).to eq("200")
        end
        it "impersonated_user" do
          allow(@user).to receive(:privgroup).and_return("dlss:testgroup1|dlss:testgroup2|dlss:testgroup3")
          get 'show', :id => @druid
          expect(response.code).to eq("403")  # Forbidden
          expect(response.body).to include 'No APO'
        end
      end
    end

    # TODO: shared examples
    describe "with APO" do
      before :each do
        allow(@item).to receive(:admin_policy_object).and_return(@item) # recursion!
      end
      # as above
    end
  end


  describe 'bulk_jobs_index' do
    it 'shows past bulk jobs for logged in users' do
      skip 'implement as part of an integration test'
    end
  end


  # valid_user with apo false ===> false
  describe 'valid_user?' do
    it 'returns false when the given object is not an APO' do
      skip 'test private methods as part of an integration test'
    end
  end
end
