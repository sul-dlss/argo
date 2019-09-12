# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowStatus do
  subject(:workflow_status) do
    described_class.new(workflow: workflow,
                        workflow_steps: workflow_steps)
  end

  let(:workflow) { Dor::Workflow::Response::Workflow.new(xml: xml) }
  let(:workflow_name) { 'accessionWF' }

  let(:workflow_steps) do
    %w[
      start-accession
      descriptive-metadata
      rights-metadata
      content-metadata
      technical-metadata
      remediate-object
      shelve
      published
      provenance-metadata
      sdr-ingest-transfer
      sdr-ingest-received
      reset-workspace
      end-accession
    ]
  end
  let(:pid) { 'druid:oo201oo0001' }
  let(:item) { Dor::Item.new pid: pid }

  describe '#pid' do
    subject { workflow_status.pid }

    let(:xml) do
      '<?xml version="1.0" encoding="UTF-8"?>
        <workflow repository="dor" objectId="druid:oo201oo0001" id="accessionWF">
        </workflow>'
    end

    it { is_expected.to eq 'druid:oo201oo0001' }
  end

  describe '#process_statuses' do
    subject { workflow_status.process_statuses }

    context 'when xml has no processes' do
      let(:xml) do
        '<?xml version="1.0" encoding="UTF-8"?>
          <workflow repository="dor" objectId="druid:oo201oo0001" id="accessionWF">
          </workflow>'
      end

      it 'has none' do
        expect(subject).to be_empty
      end
    end

    context 'when xml has processes' do
      let(:xml) do
        '<?xml version="1.0" encoding="UTF-8"?>
          <workflow repository="dor" objectId="druid:oo201oo0001" id="accessionWF">
            <process version="2" lifecycle="submitted" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:18:24-0800" status="completed" name="start-accession"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:18:58-0800" status="completed" name="technical-metadata"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:02-0800" status="completed" name="provenance-metadata"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:05-0800" status="completed" name="remediate-object"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:06-0800" status="completed" name="shelve"/>
            <process version="2" lifecycle="published" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:07-0800" status="completed" name="publish"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:09-0800" status="completed" name="sdr-ingest-transfer"/>
            <process version="2" lifecycle="accessioned" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:10-0800" status="completed" name="cleanup"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:13-0800" status="completed" name="rights-metadata"/>
            <process version="2" lifecycle="described" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:15-0800" status="completed" name="descriptive-metadata"/>
            <process version="2" elapsed="0.0" archived="true" attempts="2"
              datetime="2012-11-06T16:19:16-0800" status="completed" name="content-metadata"/>
          </workflow>'
      end

      it 'has one for each xml process' do
        expect(subject.size).to eq 13
        expect(subject).to all(be_kind_of Dor::Workflow::Response::Process)
      end
    end

    context 'when xml has multiple versions of each processes' do
      let(:xml) do
        '<?xml version="1.0" encoding="UTF-8"?>
          <workflow repository="dor" objectId="druid:oo201oo0001" id="accessionWF">
            <process version="1" elapsed="0.0" attempts="1"
              datetime="2012-11-06T16:18:58-0800" status="completed" name="technical-metadata"/>
            <process version="2" lifecycle="submitted" elapsed="0.0" attempts="1"
                datetime="2012-11-06T16:18:24-0800" status="error" name="technical-metadata"/>
            <process version="10" lifecycle="submitted" elapsed="0.0" attempts="1"
              datetime="2012-11-06T16:18:24-0800" status="queued" name="technical-metadata"/>
          </workflow>'
      end

      it 'returns the process for the most current version' do
        expect(subject.find { |n| n.name == 'technical-metadata' }.status).to eq 'queued'
      end
    end
  end

  describe '#empty?' do
    subject(:empty) { workflow_status.send(:empty?) }

    context 'when there is xml' do
      let(:xml) do
        '<?xml version="1.0" encoding="UTF-8"?>
          <workflow repository="dor" objectId="druid:oo201oo0001" id="accessionWF">
            <process version="2" lifecycle="submitted" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:18:24-0800" status="completed" name="start-accession"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:18:58-0800" status="completed" name="technical-metadata"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:02-0800" status="completed" name="provenance-metadata"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:05-0800" status="completed" name="remediate-object"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:06-0800" status="completed" name="shelve"/>
            <process version="2" lifecycle="published" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:07-0800" status="completed" name="publish"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:09-0800" status="completed" name="sdr-ingest-transfer"/>
            <process version="2" lifecycle="accessioned" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:10-0800" status="completed" name="cleanup"/>
            <process version="2" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:13-0800" status="completed" name="rights-metadata"/>
            <process version="2" lifecycle="described" elapsed="0.0" archived="true" attempts="1"
              datetime="2012-11-06T16:19:15-0800" status="completed" name="descriptive-metadata"/>
            <process version="2" elapsed="0.0" archived="true" attempts="2"
              datetime="2012-11-06T16:19:16-0800" status="completed" name="content-metadata"/>
          </workflow>'
      end

      it { is_expected.to be false }
    end

    context 'when the xml is empty' do
      let(:xml) { '' }

      it { is_expected.to be true }
    end
  end
end
