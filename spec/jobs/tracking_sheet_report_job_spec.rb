# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TrackingSheetReportJob, type: :job do
  let(:druids) { ['druid:cc111dd2222'] }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'amcollie') }
  let(:output_directory) { bulk_action.output_directory }
  let(:bulk_action) do
    create(
      :bulk_action,
      action_type: 'TrackingSheetReportJob',
      log_name: 'tmp/tracking_sheet_report_job_log.txt'
    )
  end
  let(:log_buffer) { StringIO.new }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
  end

  after do
    FileUtils.rm_rf(output_directory) if Dir.exist?(output_directory)
  end

  describe '#perform_now' do
    context 'with authorization' do
      let(:ability) { instance_double(Ability, can?: true) }
      let(:response) { { 'response' => { 'docs' => docs } } }
      let(:solr_doc) { { obj_label_tesim: 'Some label' } }
      let(:docs) { [solr_doc] }

      before do
        allow(SearchService).to receive(:query)
          .with('id:"druid:cc111dd2222"', rows: 1)
          .and_return(response)
      end

      context 'happy path' do
        it 'writes a pdf tracking sheet' do
          subject.perform(bulk_action.id,
                          druids: druids,
                          groups: groups,
                          user: user)
          expect(File).to exist(File.join(output_directory, Settings.tracking_sheet_report_job.pdf_filename))
          expect(bulk_action.druid_count_total).to eq(druids.length)
          expect(bulk_action.druid_count_fail).to eq(0)
          expect(bulk_action.druid_count_success).to eq(druids.length)
        end
      end

      context 'when there is an error writing the PDF' do
        let(:pdf) { Prawn::Document.new(page_size: [5.5.in, 8.5.in]) }

        before do
          allow(Prawn::Document).to receive(:new).and_return(pdf)
          allow(pdf).to receive(:render_file).and_raise(StandardError)
          allow(Honeybadger).to receive(:context)
          allow(Honeybadger).to receive(:notify)
          allow(Rails.logger).to receive(:error)
        end

        it 'updates the failed druid count' do
          subject.perform(bulk_action.id,
                          druids: druids,
                          groups: groups,
                          user: user)
          expect(Rails.logger).to have_received(:error)
          expect(Honeybadger).to have_received(:context)
          expect(Honeybadger).to have_received(:notify)
          expect(bulk_action.druid_count_total).to eq(druids.length)
          expect(bulk_action.druid_count_fail).to eq(druids.length)
          expect(bulk_action.druid_count_success).to eq(0)
        end
      end
    end
  end
end
