# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowService do
  describe '#workflows_for' do
    subject(:service) { described_class.workflows_for(druid: 'druid:ab123cd4567') }

    let(:xml) do
      <<~XML
        <workflows objectId="druid:ab123cd4567">
          <workflow objectId="druid:ab123cd4567" id="accessionWF">
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
          <workflow objectId="druid:ab123cd4567" id="assemblyWF">
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

    let(:accession_json) do
      { 'processes' => [
        { 'name' => 'start-accession' },
        { 'name' => 'descriptive-metadata' },
        { 'name' => 'rights-metadata' },
        { 'name' => 'content-metadata' },
        { 'name' => 'technical-metadata' },
        { 'name' => 'remediate-object' },
        { 'name' => 'shelve' },
        { 'name' => 'publish' },
        { 'name' => 'provenance-metadata' },
        { 'name' => 'sdr-ingest-transfer' },
        { 'name' => 'sdr-ingest-received' },
        { 'name' => 'reset-workspace' },
        { 'name' => 'end-accession' }
      ] }
    end

    let(:assembly_json) do
      { 'processes' => [
        { 'name' => 'start-assembly' },
        { 'name' => 'content-metadata-create' },
        { 'name' => 'jp2-create' },
        { 'name' => 'checksum-compute' },
        { 'name' => 'exif-collect' },
        { 'name' => 'accessioning-initiate' }
      ] }
    end

    let(:workflow_client) { instance_double(Dor::Workflow::Client, workflow_routes: workflow_routes) }
    let(:workflow_routes) do
      instance_double(Dor::Workflow::Client::WorkflowRoutes, all_workflows: Dor::Workflow::Response::Workflows.new(xml: xml))
    end

    before do
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)

      allow(workflow_client).to receive(:workflow_template).with('accessionWF').and_return(accession_json)
      allow(workflow_client).to receive(:workflow_template).with('assemblyWF').and_return(assembly_json)
    end

    it {
      expect(subject).to eq [
        WorkflowService::Workflow.new(name: 'accessionWF', complete: true, error_count: 0),
        WorkflowService::Workflow.new(name: 'assemblyWF', complete: false, error_count: 1)
      ]
    }
  end
end
