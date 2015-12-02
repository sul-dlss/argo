require 'spec_helper'

RSpec.describe Argo::PidGatherer do
  let(:pid_gatherer) { described_class.new }
  let(:pid_gatherer_unfiltered) { described_class.new true, false }
  describe '#pid_lists_for_full_reindex' do
    it 'queries fedora and returns list' do
      expect(pid_gatherer.pid_lists_for_full_reindex.count).to eq 10
    end
  end
  describe '#uber_apo_pids' do
    it 'returns uber apo pid' do
      expect(pid_gatherer.uber_apo_pids).to eq [SolrDocument::UBER_APO_ID]
    end
  end
  describe '#workflow_pids' do
    it 'memoizes response' do
      expect(pid_gatherer).to receive(:pids_for_model_type).once
        .with('<info:fedora/afmodel:Dor_WorkflowObject>').and_return([])
      2.times do
        expect(pid_gatherer.workflow_pids).to be_an Array
      end
    end
  end
  describe '#agreement_pids' do
    it 'memoizes response' do
      expect(pid_gatherer).to receive(:pids_for_model_type).once
        .with('<info:fedora/afmodel:agreement>').and_return([])
      2.times do
        expect(pid_gatherer.agreement_pids).to be_an Array
      end
    end
  end
  describe '#hydrus_uber_apo_pids' do
    it 'returns uber apo pid' do
      expect(pid_gatherer.hydrus_uber_apo_pids).to eq [SolrDocument::HYDRUS_UBER_APO_ID]
    end
  end
  describe '#apo_pids' do
    it 'memoizes response' do
      expect(pid_gatherer).to receive(:pids_for_model_type).once
        .with('<info:fedora/afmodel:Dor_AdminPolicyObject>').and_return([])
      2.times do
        expect(pid_gatherer.apo_pids).to be_an Array
      end
    end
  end
  describe '#hydrus_apo_pids' do
    it 'memoizes response' do
      expect(pid_gatherer).to receive(:pids_for_model_type).once
        .with('<info:fedora/afmodel:Hydrus_AdminPolicyObject>').and_return([])
      2.times do
        expect(pid_gatherer.hydrus_apo_pids).to be_an Array
      end
    end
  end
  describe '#collection_pids' do
    it 'memoizes response' do
      expect(pid_gatherer).to receive(:pids_for_model_type).once
        .with('<info:fedora/afmodel:Dor_Collection>').and_return([])
      2.times do
        expect(pid_gatherer.collection_pids).to be_an Array
      end
    end
  end
  describe '#hydrus_collection_pids' do
    it 'memoizes response' do
      expect(pid_gatherer).to receive(:pids_for_model_type).once
        .with('<info:fedora/afmodel:Hydrus_Collection>').and_return([])
      2.times do
        expect(pid_gatherer.hydrus_collection_pids).to be_an Array
      end
    end
  end
  describe '#set_pids' do
    it 'memoizes response' do
      expect(pid_gatherer).to receive(:pids_for_model_type).once
        .with('<info:fedora/afmodel:Dor_Set>').and_return([])
      2.times do
        expect(pid_gatherer.set_pids).to be_an Array
      end
    end
  end
  describe '#all_pids' do
    it 'memoizes response' do
      expect(Dor::SearchService).to receive(:iterate_over_pids).once
        .with(in_groups_of: 1000, mode: :group).and_return([])
      2.times do
        expect(pid_gatherer.all_pids).to be_an Array
      end
    end
    it 'queries fedora and only returns valid druids' do
      expect(pid_gatherer.all_pids.count).to eq 53
    end
    it 'queries fedora and returns everything' do
      expect(pid_gatherer_unfiltered.all_pids.count).to eq 57
    end
  end
  describe '#remaining_pids' do
    let(:all_pids) { [1, 2, 3, 4, 5] }
    let(:uber_apo_pids) { [1, 2] }
    let(:workflow_pids) { [3] }
    let(:agreement_pids) { [] }
    let(:hydrus_uber_apo_pids) { [] }
    let(:apo_pids) { [] }
    let(:hydrus_apo_pids) { [] }
    let(:collection_pids) { [] }
    let(:hydrus_collection_pids) { [] }
    let(:set_pids) { [] }
    it 'subtracts other pids from all_pids' do
      expect(pid_gatherer).to receive(:all_pids).and_return(all_pids)
      expect(pid_gatherer).to receive(:uber_apo_pids).and_return(uber_apo_pids)
      expect(pid_gatherer).to receive(:workflow_pids).and_return(workflow_pids)
      expect(pid_gatherer).to receive(:agreement_pids)
        .and_return(agreement_pids)
      expect(pid_gatherer).to receive(:hydrus_uber_apo_pids)
        .and_return(hydrus_uber_apo_pids)
      expect(pid_gatherer).to receive(:apo_pids).and_return(apo_pids)
      expect(pid_gatherer).to receive(:hydrus_apo_pids)
        .and_return(hydrus_apo_pids)
      expect(pid_gatherer).to receive(:collection_pids)
        .and_return(collection_pids)
      expect(pid_gatherer).to receive(:hydrus_collection_pids)
        .and_return(hydrus_collection_pids)
      expect(pid_gatherer).to receive(:set_pids)
        .and_return(set_pids)
      expect(pid_gatherer.remaining_pids).to eq [4, 5]
    end
  end
end
