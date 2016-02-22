require 'spec_helper'

describe ApplicationController, :type => :controller do

  describe '#current_user' do
    it 'should be the webauth-ed user, if they exist' do
      allow(subject).to receive(:webauth).and_return(double(:webauth_user, :login => 'sunetid', :logged_in? => true))
      expect(subject.current_user).to be_a_kind_of(User)
    end

    it 'should be a user if REMOTE_USER is provided' do
      request.env['REMOTE_USER'] = 'mods'
      expect(subject.current_user).to be_a_kind_of(User)
    end
    it 'should be nil if there is no user' do
      allow(subject).to receive(:webauth).and_return(double(:webauth_user, :logged_in? => false))
      expect(subject.current_user).to be_nil
    end
    it "should return the user's groups if impersonation info wasn't specified" do
      webauth_privgroup_str = 'dlss:testgroup1|dlss:testgroup2|dlss:testgroup3'
      allow(subject).to receive(:webauth).and_return(double(:webauth_user, :login => 'sunetid', :logged_in? => true, :privgroup => webauth_privgroup_str))

      # note the check for sunetid:sunetid.  user's sunetid should be prepended to the group list returned by webauth.
      # note also that workgroup: should be prepended to each workgroup name, and sunetid: should be prepended to the user's
      # sunetid.
      expected_groups = ['sunetid:sunetid'] + webauth_privgroup_str.split(/\|/).collect { |g| "workgroup:#{g}" }
      expect(subject.current_user.groups).to eq(expected_groups)
    end
    it "should override the user's groups if impersonation info was specified" do
      webauth_privgroup_str = 'dlss:testgroup1|dlss:testgroup2|dlss:testgroup3'
      impersonated_groups = ['workgroup:dlss:impersonatedgroup1', 'workgroup:dlss:impersonatedgroup2']
      session[:groups] = impersonated_groups

      allow(subject).to receive(:webauth).and_return(double(:webauth_user, :login => 'sunetid', :logged_in? => true, :privgroup => webauth_privgroup_str))

      expect(subject.current_user.groups).to eq(impersonated_groups)
    end
  end

  describe '#find_druid' do
    # anonymous controller for testing flash warnings.
    controller do
      def show
        find_druid(params[:id])
        render :text => params[:id]
      end
    end
    def load_fixture_class(druid, klass)
      item = instantiate_fixture(druid, klass)
      expect(Dor).to receive(:find).once.and_call_original
      object = subject.send(:find_druid, item.pid)
      expect(object.pid).to eq(item.pid)
      expect(object).to be_instance_of klass
    end
    it 'can load a Dor::Item fixture' do
      load_fixture_class('druid:qq613vj0238', Dor::Item)
    end
    it 'can load a Dor::AdminPolicyObject fixture' do
      load_fixture_class('druid:fg464dn8891', Dor::AdminPolicyObject)
    end
    it 'can load a Dor::Collection fixture' do
      load_fixture_class('druid:pb873ty1662', Dor::Collection)
    end
    it 'can load a Dor::Set fixture' do
      skip('There is no Dor::Set fixture available')
      load_fixture_class('druid:???????????', Dor::Set)
    end
    it 'can load a Dor::WorkflowObject fixture' do
      load_fixture_class('druid:fy957df3135', Dor::WorkflowObject)
    end
    it 'allows Dor.find to retrieve an invalid DRUID' do
      expect(Dor).to receive(:find).once
      subject.send(:find_druid, 'abc123')
    end
    context 'with blank DRUID' do
      it 'raises ActionController::BadRequest' do
        expect{ subject.send(:find_druid, '')   }.to raise_error(ActionController::BadRequest)
        expect{ subject.send(:find_druid, nil)  }.to raise_error(ActionController::BadRequest)
      end
      it 'logs an error' do
        expect(subject.logger).to receive(:error).once
        log_in_as_mock_user(subject)
        get 'show', id: ''
      end
    end
    context 'with missing DRUID' do
      let(:druid) { 'druid:aa111aa1111' }
      it 'raises ActiveFedora::ObjectNotFoundError' do
        expect{ subject.send(:find_druid, druid) }.to raise_error(ActiveFedora::ObjectNotFoundError)
      end
      it 'logs an error' do
        expect(subject.logger).to receive(:error).once
        log_in_as_mock_user(subject)
        get 'show', id: druid
      end
      it 'responds 404' do
        log_in_as_mock_user(subject)
        get 'show', id: druid
        expect(response).to have_http_status(:missing)
        expect(response.body).to include 'Object Not Found'
        expect(response.body).to include druid
      end
    end
    context 'with invalid DRUID' do
      let(:druid) { 'abc123' }
      it 'raises Rubydora::FedoraInvalidRequest' do
        expect{ subject.send(:find_druid, druid) }.to raise_error(Rubydora::FedoraInvalidRequest)
      end
      it 'logs a warning' do
        expect(subject.logger).to receive(:warn).once
        expect{ subject.send(:find_druid, druid) }.to raise_error(Rubydora::FedoraInvalidRequest)
      end
      it 'flashes an alert' do
        log_in_as_mock_user(subject)
        get 'show', id: druid
        expect(flash[:alert]).to include "Trying to find an invalid DRUID: #{druid}"
      end
    end
  end

  describe '#development_only!' do
    it 'should be called in development mode' do
      allow(Rails.env).to receive(:development?).and_return(true)
      called = false
      block = lambda { called = true }
      subject.send(:development_only!, &block)
      expect(called).to be true
    end

    it 'should be called when DOR_SERVICES_DEBUG_MODE is set' do
      expect(ENV).to receive(:[]).with('DOR_SERVICES_DEBUG_MODE').and_return('true')
      called = false
      block = lambda { called = true }
      subject.send(:development_only!, &block)
      expect(called).to be true
    end

    it 'should otherwise do nothing' do
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
