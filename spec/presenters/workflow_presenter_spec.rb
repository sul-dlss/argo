# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkflowPresenter do
  subject(:presenter) { described_class.new(object: item, workflow_name: 'accessionWF', xml: xml) }

  let(:pid) { 'druid:oo201oo0001' }
  let(:item) { Dor::Item.new pid: pid }

  describe '#processes' do
    subject { presenter.processes }

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
      end
    end
  end

  describe '#workflow_document' do
    subject(:workflow_document) { presenter.send(:workflow_document) }

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

      it { is_expected.to be_kind_of Dor::Workflow::Document }
    end

    context 'when the xml is empty' do
      let(:xml) { '' }

      it { is_expected.to be_nil }
    end
  end
end
