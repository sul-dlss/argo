require "rails_helper"

RSpec.describe BulkActionsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/bulk_actions").to route_to("bulk_actions#index")
    end

    it "routes to #new" do
      expect(:get => "/bulk_actions/new").to route_to("bulk_actions#new")
    end

    it "routes to #show" do
      expect(:get => "/bulk_actions/1").to route_to("bulk_actions#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/bulk_actions/1/edit").to route_to("bulk_actions#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/bulk_actions").to route_to("bulk_actions#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/bulk_actions/1").to route_to("bulk_actions#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/bulk_actions/1").to route_to("bulk_actions#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/bulk_actions/1").to route_to("bulk_actions#destroy", :id => "1")
    end

  end
end
