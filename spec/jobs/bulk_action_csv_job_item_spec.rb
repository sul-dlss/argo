# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkActionCsvJobItem do
  subject(:job) { instance_double(BulkActionCsvJob, user: 'a_user', ability:) }

  let(:druid) { 'druid:bb111cc2222' }
  let(:row) { instance_double(CSV::Row) }
  let(:ability) { instance_double(Ability) }

  let(:bulk_action_item) { described_class.new(druid:, index: 2, job:, row:) }

  before do
    # If this is not stubbed, row persists across tests and causes failures.
    allow(Honeybadger).to receive(:context)
  end

  describe '.success!' do
    before do
      allow(job).to receive(:success!)
    end

    it 'calls job.success!' do
      bulk_action_item.success!(message: 'Testing successful')
      expect(job).to have_received(:success!).with(druid:, message: 'Testing successful', index: 2)
    end
  end

  describe '.failure!' do
    before do
      allow(job).to receive(:failure!)
    end

    it 'calls job.failure!' do
      bulk_action_item.failure!(message: 'Testing failed')
      expect(job).to have_received(:failure!).with(druid:, message: 'Testing failed', index: 2)
    end
  end
end
