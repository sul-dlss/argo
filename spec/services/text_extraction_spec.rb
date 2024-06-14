# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TextExtraction do
  subject(:text_extraction) { described_class.new(cocina_object, languages:, already_opened:) }

  let(:druid) { 'druid:bg139xz7624' }
  let(:version) { 2 }
  let(:cocina_object) { instance_double(Cocina::Models::DRO, dro?: dro, externalIdentifier: druid, version:, type: object_type) }
  let(:languages) { ['English'] }
  let(:dro) { true }
  let(:object_type) { 'https://cocina.sul.stanford.edu/models/document' }
  let(:ocr_wf) { 'ocrWF' }
  let(:already_opened) { true }

  describe '#possible?' do
    context 'when the object is a document' do
      it 'returns true' do
        expect(text_extraction.possible?).to be true
      end
    end

    context 'when the object is an image' do
      let(:object_type) { 'https://cocina.sul.stanford.edu/models/image' }

      it 'returns true' do
        expect(text_extraction.possible?).to be true
      end
    end

    context 'when the object is a book' do
      let(:object_type) { 'https://cocina.sul.stanford.edu/models/book' }

      it 'returns true' do
        expect(text_extraction.possible?).to be true
      end
    end

    context 'when the object is not an item' do
      let(:dro) { false }

      it 'returns false' do
        expect(text_extraction.possible?).to be false
      end
    end

    context 'when the object is not a document, image or book' do
      let(:object_type) { 'https://cocina.sul.stanford.edu/models/map' }

      it 'returns false' do
        expect(text_extraction.possible?).to be false
      end
    end

    context 'when cocina is nil' do
      let(:cocina_object) { nil }

      it 'returns false' do
        expect(text_extraction.possible?).to be false
      end
    end
  end

  describe '#wf_name' do
    context 'when the object is a document' do
      it 'returns ocrWF' do
        expect(text_extraction.wf_name).to eq 'ocrWF'
      end
    end

    context 'when the object is an image' do
      let(:object_type) { 'https://cocina.sul.stanford.edu/models/image' }

      it 'returns ocrWF' do
        expect(text_extraction.wf_name).to eq 'ocrWF'
      end
    end

    context 'when the object is a book' do
      let(:object_type) { 'https://cocina.sul.stanford.edu/models/book' }

      it 'returns ocrWF' do
        expect(text_extraction.wf_name).to eq 'ocrWF'
      end
    end

    context 'when the object is not a document, image or book' do
      let(:object_type) { 'https://cocina.sul.stanford.edu/models/map' }

      it 'returns nil' do
        expect(text_extraction.wf_name).to be_nil
      end
    end
  end

  describe '#start' do
    let(:client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: true, lifecycle: Time.zone.now) }
    let(:context) { { manuallyCorrectedOCR: false, ocrLanguages: languages, runOCR: true } }

    before do
      allow(WorkflowClientFactory).to receive(:build).and_return(client)
    end

    context 'when the object is already opened' do
      context 'when the object is a document' do
        it 'starts ocrWF and returns true' do
          expect(text_extraction.start).to be true
          expect(client).to have_received(:create_workflow_by_name).with(druid, ocr_wf, version:, context:)
        end
      end

      context 'when the object is an image' do
        let(:object_type) { 'https://cocina.sul.stanford.edu/models/image' }

        it 'starts ocrWF and returns true' do
          expect(text_extraction.start).to be true
          expect(client).to have_received(:create_workflow_by_name).with(druid, ocr_wf, version:, context:)
        end
      end

      context 'when the object is a book' do
        let(:object_type) { 'https://cocina.sul.stanford.edu/models/book' }

        it 'starts ocrWF and returns true' do
          expect(text_extraction.start).to be true
          expect(client).to have_received(:create_workflow_by_name).with(druid, ocr_wf, version:, context:)
        end
      end
    end

    context 'when the object is not already opened' do
      let(:already_opened) { false }

      context 'when the object is a document' do
        it 'starts ocrWF for the next version and returns true' do
          expect(text_extraction.start).to be true
          expect(client).to have_received(:create_workflow_by_name).with(druid, ocr_wf, version: version + 1, context:)
        end
      end

      context 'when the object is an image' do
        let(:object_type) { 'https://cocina.sul.stanford.edu/models/image' }

        it 'starts ocrWF and returns true' do
          expect(text_extraction.start).to be true
          expect(client).to have_received(:create_workflow_by_name).with(druid, ocr_wf, version: version + 1, context:)
        end
      end

      context 'when the object is a book' do
        let(:object_type) { 'https://cocina.sul.stanford.edu/models/book' }

        it 'starts ocrWF and returns true' do
          expect(text_extraction.start).to be true
          expect(client).to have_received(:create_workflow_by_name).with(druid, ocr_wf, version: version + 1, context:)
        end
      end
    end

    context 'when the object is not an item' do
      let(:dro) { false }

      it 'returns false and does nothing' do
        expect(text_extraction.start).to be false
        expect(client).not_to have_received(:create_workflow_by_name).with(druid, ocr_wf, version:, context:)
      end
    end

    context 'when the object is not a document, image or book' do
      let(:object_type) { 'https://cocina.sul.stanford.edu/models/map' }

      it 'returns false and does nothing' do
        expect(text_extraction.start).to be false
        expect(client).not_to have_received(:create_workflow_by_name).with(druid, ocr_wf, version:, context:)
      end
    end
  end
end
