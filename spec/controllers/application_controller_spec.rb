require 'spec_helper'

describe ApplicationController do

  describe "#current_user" do
    it "should be the webauth-ed user, if they exist" do
      subject.stub(:webauth).and_return(mock(:webauth_user, :login => 'sunetid', :logged_in? => true))
      subject.current_user.should be_a_kind_of(User)
    end

    it "should be nil if there is no user" do
      subject.stub(:webauth).and_return(mock(:webauth_user, :logged_in? => false))
      subject.current_user.should be_nil
    end
  end

  describe "#development_only!" do
    it "should be called in development mode" do
      Rails.env.stub(:development?).and_return(true)
      called = false
      block = lambda { called = true }
      subject.send(:development_only!, &block)
      called.should be_true
    end

    it "should be called when DOR_SERVICES_DEBUG_MODE is set" do
      ENV.should_receive(:[]).with('DOR_SERVICES_DEBUG_MODE').and_return('true')
      called = false
      block = lambda { called = true }
      subject.send(:development_only!, &block)
      called.should be_true
    end

    it "should otherwise do nothing" do
      Rails.env.stub(:development?).and_return(false)
      ENV.should_receive(:[]).with('DOR_SERVICES_DEBUG_MODE').and_return(nil)
      subject.should_receive(:render)
      called = false
      block = lambda { called = true }
      subject.send(:development_only!, &block)
      called.should be_false
    end

  end
end
