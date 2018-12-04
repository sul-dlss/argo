# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationController, type: :controller do
  describe '#current_user' do
    before do
      sign_in User.create(sunetid: 'bob')
    end

    subject { controller.current_user }

    it 'sets impersonated_groups if impersonation info was in the session' do
      impersonated_groups = ['workgroup:dlss:impersonatedgroup1', 'workgroup:dlss:impersonatedgroup2']
      session[:groups] = impersonated_groups
      expect(subject.groups).to eq(impersonated_groups)
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
