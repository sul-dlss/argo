# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DatePresenter do
  subject(:presenter) do
    described_class.render(mock_date)
  end

  describe '#render' do
    context 'when the date is nil' do
      let(:mock_date) { nil }

      it 'returns an empty string' do
        expect(subject).to eq ''
      end
    end

    context 'when the date is a valid DateTime value' do
      let(:mock_date) { DateTime.parse('2022-05-06') }

      context 'when the date is successfully translated' do
        it 'returns an i18n translated date' do
          expect(subject).to eq '2022-05-06 12:00AM'
        end
      end

      context 'when the date cannot be translated' do
        it 'rescues the StandardError and returns a date string' do
          allow(I18n).to receive(:l).and_raise(StandardError, 'ruh roh')
          expect(subject).to eq '2022-05-06 12:00AM'
        end
      end
    end
  end
end
