# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowService do
  let(:druid) { 'druid:bc123cd4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  describe '#workflows_for' do
    subject(:service) { described_class.workflows_for(druid:) }

    let(:xml) do
      <<~XML
        <workflows objectId="druid:bc123cd4567">
          <workflow objectId="druid:bc123cd4567" id="accessionWF">
            <process version="1" priority="0" note="" lifecycle="submitted" laneId="default" elapsed="" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="start-accession"/>
            <process version="1" priority="0" note="common-accessioning-stage-a.stanford.edu" lifecycle="described" laneId="default" elapsed="0.258" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="descriptive-metadata"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="" laneId="default" elapsed="0.188" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="rights-metadata"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="" laneId="default" elapsed="0.255" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="content-metadata"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="" laneId="default" elapsed="0.948" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="technical-metadata"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="" laneId="default" elapsed="0.15" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="remediate-object"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="" laneId="default" elapsed="0.479" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="shelve"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="published" laneId="default" elapsed="1.188" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="publish"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="" laneId="default" elapsed="0.251" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="provenance-metadata"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="" laneId="default" elapsed="2.257" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="sdr-ingest-transfer"/>
            <process version="1" priority="0" note="preservationIngestWF completed on preservation-robots1-stage.stanford.edu" lifecycle="deposited" laneId="default" elapsed="1.0" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="sdr-ingest-received"/>
            <process version="1" priority="0" note="common-accessioning-stage-b.stanford.edu" lifecycle="" laneId="default" elapsed="0.246" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="reset-workspace"/>
            <process version="1" priority="0" note="common-accessioning-stage-a.stanford.edu" lifecycle="accessioned" laneId="default" elapsed="1.196" attempts="0" datetime="2019-01-28T20:41:12+00:00" status="completed" name="end-accession"/>
          </workflow>
          <workflow objectId="druid:bc123cd4567" id="assemblyWF">
            <process version="1" priority="0" note="" lifecycle="pipelined" laneId="default" elapsed="" attempts="0" datetime="2019-01-28T20:40:18+00:00" status="completed" name="start-assembly"/>
            <process version="1" priority="0" note="" lifecycle="" laneId="default" elapsed="" attempts="0" datetime="2019-01-28T20:40:18+00:00" status="skipped" name="jp2-create"/>
            <process version="1" priority="0" note="sul-robots1-test.stanford.edu" lifecycle="" laneId="default" elapsed="0.25" attempts="0" datetime="2019-01-28T20:40:18+00:00" status="completed" name="checksum-compute"/>
            <process version="1" priority="0" note="sul-robots1-test.stanford.edu" lifecycle="" laneId="default" elapsed="0.306" attempts="0" datetime="2019-01-28T20:40:18+00:00" status="completed" name="exif-collect"/>
            <process version="1" priority="0" note="sul-robots2-test.stanford.edu" lifecycle="" laneId="default" elapsed="0.736" attempts="0" datetime="2019-01-28T20:40:18+00:00" status="completed" name="accessioning-initiate"/>
            <process version="2" priority="0" note="" lifecycle="" laneId="default" elapsed="" attempts="0" datetime="2019-01-29T22:51:09+00:00" status="completed" name="start-assembly"/>
            <process version="2" priority="0" note="contentMetadata.xml exists" lifecycle="" laneId="default" elapsed="0.278" attempts="0" datetime="2019-01-29T22:51:09+00:00" status="skipped" name="content-metadata-create"/>
            <process version="2" priority="0" note="" lifecycle="" laneId="default" elapsed="0.0" attempts="0" datetime="2019-01-29T22:51:09+00:00" status="error" name="jp2-create"/>
            <process version="2" priority="0" note="" lifecycle="" laneId="default" elapsed="0.0" attempts="0" datetime="2019-01-29T22:51:09+00:00" status="queued" name="checksum-compute"/>
            <process version="2" priority="0" note="" lifecycle="" laneId="default" elapsed="0.0" attempts="0" datetime="2019-01-29T22:51:09+00:00" status="queued" name="exif-collect"/>
            <process version="2" priority="0" note="" lifecycle="" laneId="default" elapsed="0.0" attempts="0" datetime="2019-01-29T22:51:09+00:00" status="queued" name="accessioning-initiate"/>
          </workflow>
        </workflows>
      XML
    end

    before do
      allow(object_client).to receive(:workflows).and_return(Dor::Services::Response::Workflows.new(xml: Nokogiri::XML(xml)))
    end

    it 'returns two workflow response objects' do
      expect(subject.first.workflow_name).to eq('accessionWF')
      expect(subject.first).to be_complete
      expect(subject.first.error_count).to be_zero
      expect(subject.second.workflow_name).to eq('assemblyWF')
      expect(subject.second).not_to be_complete
      expect(subject.second.error_count).to eq(1)
    end
  end

  describe '#accessioned?' do
    let(:milestones_client) { instance_double(Dor::Services::Client::Milestones) }

    before do
      allow(object_client).to receive(:milestones).and_return(milestones_client)
      allow(milestones_client).to receive(:date).with(milestone_name: 'accessioned').and_return(accessioned_date)
    end

    context 'if the accessioned lifecycle exists' do
      let(:accessioned_date) { '2022-04-20 21:55:25 +0000' }

      it 'returns true' do
        expect(described_class.accessioned?(druid:)).to be true
      end
    end

    context 'if the accessioned lifecycle does not exist' do
      let(:accessioned_date) { nil }

      it 'returns false' do
        expect(described_class.accessioned?(druid:)).to be false
      end
    end
  end

  describe '#submitted' do
    let(:milestones_client) { instance_double(Dor::Services::Client::Milestones) }

    before do
      allow(object_client).to receive(:milestones).and_return(milestones_client)
      allow(milestones_client).to receive(:date).with(milestone_name: 'submitted').and_return(submitted_date)
    end

    context 'if the submitted lifecycle exists' do
      let(:submitted_date) { '2022-04-20 21:55:25 +0000' }

      it 'returns true' do
        expect(described_class.submitted?(druid:)).to be true
      end
    end

    context 'if the submitted lifecycle does not exist' do
      let(:submitted_date) { nil }

      it 'returns false' do
        expect(described_class.submitted?(druid:)).to be false
      end
    end
  end

  describe '#published' do
    let(:milestones_client) { instance_double(Dor::Services::Client::Milestones) }

    before do
      allow(object_client).to receive(:milestones).and_return(milestones_client)
      allow(milestones_client).to receive(:date).with(milestone_name: 'published').and_return(published_date)
    end

    context 'if the published lifecycle exists' do
      let(:published_date) { '2022-04-20 21:55:25 +0000' }

      it 'returns true' do
        expect(described_class.published?(druid:)).to be true
      end
    end

    context 'if the published lifecycle does not exist' do
      let(:published_date) { nil }

      it 'returns false' do
        expect(described_class.published?(druid:)).to be false
      end
    end
  end

  describe '#workflow_active?' do
    let(:version) { 2 }
    let(:wf_name) { 'assemblyWF' }
    let(:workflow_client) { instance_double(Dor::Services::Client::ObjectWorkflow, find: fake_workflow) }
    let(:fake_workflow) { instance_double(Dor::Services::Response::Workflow, active_for?: active_for) }

    before do
      allow(object_client).to receive(:workflow).with(wf_name).and_return(workflow_client)
    end

    context 'when not active' do
      let(:active_for) { false }

      it 'returns false' do
        expect(described_class.workflow_active?(druid:, version:, wf_name:)).to be false
      end
    end

    context 'when active' do
      let(:active_for) { true }

      it 'returns true' do
        expect(described_class.workflow_active?(druid:, version:, wf_name:)).to be true
      end
    end
  end
end
