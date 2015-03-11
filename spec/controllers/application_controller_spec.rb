require 'spec_helper'

describe ApplicationController, :type => :controller do

  describe "#current_user" do
    it "should be the webauth-ed user, if they exist" do
      allow(subject).to receive(:webauth).and_return(double(:webauth_user, :login => 'sunetid', :logged_in? => true))
      expect(subject.current_user).to be_a_kind_of(User)
    end

    it "should be a user if REMOTE_USER is provided" do
      request.env['REMOTE_USER'] = 'mods'
      expect(subject.current_user).to be_a_kind_of(User)
    end
    it "should be nil if there is no user" do
      allow(subject).to receive(:webauth).and_return(double(:webauth_user, :logged_in? => false))
      expect(subject.current_user).to be_nil
    end
    it "should return the user's groups if impersonation info wasn't specified" do
      webauth_privgroup_str = "dlss:testgroup1|dlss:testgroup2|dlss:testgroup3"
      allow(subject).to receive(:webauth).and_return(double(:webauth_user, :login => 'sunetid', :logged_in? => true, :privgroup => webauth_privgroup_str))

      # note the check for sunetid:sunetid.  user's sunetid should be prepended to the group list returned by webauth.
      # note also that workgroup: should be prepended to each workgroup name.
      expected_groups = ['sunetid:sunetid'] + webauth_privgroup_str.split(/\|/).collect { |g| "workgroup:#{g}" }
      expect(subject.current_user.groups).to eq(expected_groups)
    end
    it "should override the user's groups if impersonation info was specified" do
      webauth_privgroup_str = "dlss:testgroup1|dlss:testgroup2|dlss:testgroup3"
      impersonated_groups = ["workgroup:dlss:impersonatedgroup1", "workgroup:dlss:impersonatedgroup2"]
      session[:groups] = impersonated_groups

      allow(subject).to receive(:webauth).and_return(double(:webauth_user, :login => 'sunetid', :logged_in? => true, :privgroup => webauth_privgroup_str))

      expect(subject.current_user.groups).to eq(impersonated_groups)
    end
  end

  describe "#development_only!" do
    it "should be called in development mode" do
      allow(Rails.env).to receive(:development?).and_return(true)
      called = false
      block = lambda { called = true }
      subject.send(:development_only!, &block)
      expect(called).to be true
    end

    it "should be called when DOR_SERVICES_DEBUG_MODE is set" do
      expect(ENV).to receive(:[]).with('DOR_SERVICES_DEBUG_MODE').and_return('true')
      called = false
      block = lambda { called = true }
      subject.send(:development_only!, &block)
      expect(called).to be true
    end

    it "should otherwise do nothing" do
      allow(Rails.env).to receive(:development?).and_return(false)
      expect(ENV).to receive(:[]).with('DOR_SERVICES_DEBUG_MODE').and_return(nil)
      expect(subject).to receive(:render)
      called = false
      block = lambda { called = true }
      subject.send(:development_only!, &block)
      expect(called).to be false
    end

  end
end
