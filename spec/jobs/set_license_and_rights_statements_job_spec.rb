# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetLicenseAndRightsStatementsJob, type: :job do
  let(:bulk_action) { create(:bulk_action) }
  let(:groups) { [] }
  let(:pids) { ['druid:123', 'druid:456'] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }

  before do
    allow(BulkAction).to receive(:find).and_return(bulk_action)
  end

  context 'when setter runs without raising' do
    let(:license_uri) { 'http://my.license.example.com/' }
    let(:params) do
      {
        pids: pids,
        groups: groups,
        user: user,
        copyright_statement_option: '0',
        copyright_statement: '',
        license_option: '1',
        license: license_uri,
        use_statement_option: '0',
        use_statement: ''
      }.with_indifferent_access
    end

    before do
      allow(LicenseAndRightsStatementsSetter).to receive(:set).and_return(nil)
      described_class.perform_now(bulk_action.id, params)
    end

    it 'increments the success counter' do
      expect(bulk_action.druid_count_success).to eq(pids.size)
    end

    it 'invokes the license setter as expected' do
      expect(LicenseAndRightsStatementsSetter).to have_received(:set)
        .with(
          ability: instance_of(Ability),
          druid: /druid:\d+/,
          license: license_uri
        )
        .exactly(pids.size)
        .times
    end
  end

  context 'when setter raises exceptions' do
    let(:copyright_statement) { 'new copyright statement' }
    let(:params) do
      {
        pids: pids,
        groups: groups,
        user: user,
        copyright_statement_option: '1',
        copyright_statement: copyright_statement,
        license_option: '0',
        license: '',
        use_statement_option: '1',
        use_statement: use_statement
      }.with_indifferent_access
    end
    let(:use_statement) { 'new use statement' }

    before do
      allow(LicenseAndRightsStatementsSetter).to receive(:set).and_raise(RuntimeError)
      described_class.perform_now(bulk_action.id, params)
    end

    it 'increments the failure counter' do
      expect(bulk_action.druid_count_fail).to eq(pids.size)
    end

    it 'invokes the license setter as expected' do
      expect(LicenseAndRightsStatementsSetter).to have_received(:set)
        .with(
          ability: instance_of(Ability),
          druid: /druid:\d+/,
          copyright: copyright_statement,
          use_statement: use_statement
        )
        .exactly(pids.size)
        .times
    end
  end
end
