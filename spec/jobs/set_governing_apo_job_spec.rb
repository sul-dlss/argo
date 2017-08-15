require 'spec_helper'

describe SetGoverningApoJob do
  let(:bulk_action_no_process_callback) do
    bulk_action = build(
      :bulk_action,
      action_type: 'SetGoverningApoJob'
    )
    expect(bulk_action).to receive(:process_bulk_action_type)
    bulk_action.save
    bulk_action
  end

  let(:new_apo_id) { 'druid:aa111bb2222' }
  let(:webauth) { { 'privgroup' => 'dorstuff', 'login' => 'someuser' } }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action_no_process_callback)
  end

  describe '#perform' do
    let(:pids) { ['druid:bb111cc2222', 'druid:cc111dd2222', 'druid:dd111ee2222'] }
    let(:params) do
      {
        pids: pids,
        set_governing_apo: { 'new_apo_id' => new_apo_id },
        webauth: webauth
      }
    end

    context 'in a happy world' do
      it 'updates the total druid count, attempts to update the APO for each druid, and commits to solr' do
        pids.each do |pid|
          expect(subject).to receive(:set_governing_apo_and_index_safely).with(pid, instance_of(File))
        end
        expect(Dor::SearchService.solr).to receive(:commit)
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(bulk_action_no_process_callback.druid_count_total).to eq pids.length
      end

      it 'logs info about progress' do
        allow(subject).to receive(:set_governing_apo_and_index_safely)
        allow(Dor::SearchService.solr).to receive(:commit)

        buffer = StringIO.new
        expect(subject).to receive(:with_bulk_action_log).and_yield(buffer)

        subject.perform(bulk_action_no_process_callback.id, params)

        bulk_action_id = bulk_action_no_process_callback.id
        expect(buffer.string).to include "Starting SetGoverningApoJob for BulkAction #{bulk_action_id}"
        pids.each do |pid|
          expect(buffer.string).to include "SetGoverningApoJob: Starting update for #{pid} (bulk_action.id=#{bulk_action_id})"
          expect(buffer.string).to include "SetGoverningApoJob: Finished update for #{pid} (bulk_action.id=#{bulk_action_id})"
        end
        expect(buffer.string).to include "Finished SetGoverningApoJob for BulkAction #{bulk_action_id}"
      end

      # it might be cleaner to break the testing here into smaller cases for #set_governing_apo_and_index_safely,
      # assuming one is inclined to test private methods, but it also seemed reasonable to do a slightly more end-to-end
      # test of #perform, to prove that common failure cases for individual objects wouldn't fail the whole run.
      it 'increments the failure and success counts, keeps running even if an individual update fails, and logs status of each update' do
        buffer = StringIO.new
        expect(subject).to receive(:with_bulk_action_log).and_yield(buffer)

        item1 = double(Dor::Item)
        item3 = double(Dor::Item)
        apo = double(Dor::AdminPolicyObject)

        expect(Dor).to receive(:find).with(pids[0]).and_return(item1)
        expect(subject).to receive(:can_set_governing_apo?).with(item1).and_return true
        expect(Dor).to receive(:find).with(pids[1]).and_raise(ActiveFedora::ObjectNotFoundError)
        expect(Dor).to receive(:find).with(pids[2]).and_return(item3)
        expect(subject).to receive(:can_set_governing_apo?).with(item3).and_return false

        expect(Dor).to receive(:find).with(new_apo_id).and_return(apo)
        idmd = double(Dor::IdentityMetadataDS, adminPolicy: double(Dor::AdminPolicyObject))
        expect(item1).to receive(:admin_policy_object=).with(apo)
        expect(item1).to receive(:identityMetadata).and_return(idmd).exactly(:twice)
        expect(idmd).to receive(:adminPolicy=).with(nil)
        expect(item1).to receive(:save)
        expect(item1).to receive(:to_solr).and_return(field: 'value')
        expect(item1).to receive(:allows_modification?).and_return true
        expect(Dor::SearchService.solr).to receive(:add).with(field: 'value').exactly(:once)

        expect(item3).not_to receive(:admin_policy_object=)
        expect(item3).not_to receive(:identityMetadata)
        expect(item3).not_to receive(:save)

        expect(Dor::SearchService.solr).to receive(:commit)

        subject.perform(bulk_action_no_process_callback.id, params)
        expect(bulk_action_no_process_callback.druid_count_success).to eq 1
        expect(bulk_action_no_process_callback.druid_count_fail).to eq 2

        bulk_action_id = bulk_action_no_process_callback.id
        expect(buffer.string).to include "SetGoverningApoJob: Successfully updated #{pids[0]} (bulk_action.id=#{bulk_action_id})"
        expect(buffer.string).to include "SetGoverningApoJob: Unexpected error for #{pids[1]} (bulk_action.id=#{bulk_action_id}): ActiveFedora::ObjectNotFoundError"
        expect(buffer.string).to include "SetGoverningApoJob: Unexpected error for #{pids[2]} (bulk_action.id=#{bulk_action_id}): user not allowed to move to target apo"
      end
    end
  end

  describe '#can_set_governing_apo?' do
    let(:pid) { '123' }
    let(:obj) { double(Dor::Collection, pid: pid) }
    let(:ability) { double(Ability) }

    before do
      subject.instance_variable_set(:@new_apo_id, new_apo_id)
      subject.instance_variable_set(:@ability, ability)
    end

    it 'returns false for an object that the user cannot manage' do
      allow(ability).to receive(:can?).with(:manage_governing_apo, obj, new_apo_id).and_return(false)
      expect(subject.send(:can_set_governing_apo?, obj)).to be_falsy
    end

    it 'does nothing for an object that the user can manage' do
      allow(ability).to receive(:can?).with(:manage_governing_apo, obj, new_apo_id).and_return(true)
      expect(subject.send(:can_set_governing_apo?, obj)).to be_truthy
    end
  end

  describe '#open_new_version' do
    before :each do
      @dor_object = double(pid: 'druid:123abc')
      @workflow = double('workflow')
      @log = double('log')
      @current_user = mock_user(is_admin?: true)
    end

    it 'opens a new version if the workflow status allows' do
      expect(DorObjectWorkflowStatus).to receive(:new).with(@dor_object.pid).and_return(@workflow)
      expect(@workflow).to receive(:can_open_version?).and_return(true)
      expect(@dor_object).to receive(:open_new_version).with({
        vers_md_upd_info: {
          significance: 'minor',
          description: 'Set new governing APO',
          opening_user_name: @current_user.to_s
        }
      })
      allow(subject).to receive(:current_user).and_return(@current_user)

      subject.send(:open_new_version, @dor_object, @log)
    end

    it 'does not open a new version if rejected by the workflow status' do
      expect(@log).to receive(:puts).with(/Unable to open new version for/)
      expect(DorObjectWorkflowStatus).to receive(:new).with(@dor_object.pid).and_return(@workflow)
      expect(@workflow).to receive(:can_open_version?).and_return(false)
      expect(@dor_object).not_to receive(:open_new_version)
      subject.send(:open_new_version, @dor_object, @log)
    end

    it 'fails with an error message if something goes wrong updating the version' do
      expect(@log).to receive(:puts).with(/Failed to open new version for/)
      expect(DorObjectWorkflowStatus).to receive(:new).with(@dor_object.pid).and_return(@workflow)
      expect(@workflow).to receive(:can_open_version?).and_return(true)
      expect(@dor_object).to receive(:open_new_version).with({
        vers_md_upd_info: {
          significance: 'minor',
          description: 'Set new governing APO',
          opening_user_name: @current_user.to_s
        }
      }).and_raise Dor::Exception
      allow(subject).to receive(:current_user).and_return(@current_user)
      subject.send(:open_new_version, @dor_object, @log)
    end
  end

  describe '#ability' do
    before { subject.instance_variable_set(:@webauth, webauth) }

    it 'caches the result' do
      user = double(User)
      expect(User).to receive(:find_or_create_by_webauth).with(webauth).and_return(user).exactly(:once)
      ability = double(Ability)
      expect(Ability).to receive(:new).with(user).and_return(ability).exactly(:once)

      expect(subject.send(:ability)).to be(ability)
      expect(subject.send(:ability)).to be(ability)
    end
  end
end
