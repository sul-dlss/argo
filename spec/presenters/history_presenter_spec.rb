# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HistoryPresenter do
  subject(:presenter) do
    described_class.new(item)
  end

  let(:pid) { 'druid:oo201oo0001' }
  let(:item) { Dor::Item.new pid: pid }

  describe '#milestones' do
    subject { presenter.milestones }

    let(:lifecycle) do
      <<~XML
        <lifecycle objectId="druid:jc553nr8433">
          <milestone date="2019-03-12T18:16:13+00:00" version="1">registered</milestone>
          <milestone date="2019-03-12T18:26:47+00:00" version="1">submitted</milestone>
          <milestone date="2019-03-12T18:27:18+00:00" version="1">described</milestone>
          <milestone date="2019-03-12T18:29:38+00:00" version="1">published</milestone>
          <milestone date="2019-03-12T18:33:35+00:00" version="1">deposited</milestone>
          <milestone date="2019-03-12T18:34:10+00:00" version="1">accessioned</milestone>
          <milestone date="2019-03-12T18:50:33+00:00" version="2">opened</milestone>
          <milestone date="2019-03-12T18:50:45+00:00" version="2">submitted</milestone>
          <milestone date="2019-03-12T18:51:04+00:00" version="2">described</milestone>
          <milestone date="2019-03-12T18:53:30+00:00" version="2">published</milestone>
          <milestone date="2019-03-12T18:56:02+00:00" version="2">deposited</milestone>
          <milestone date="2019-03-12T18:56:46+00:00" version="2">accessioned</milestone>
          <milestone date="2019-03-12T21:14:15+00:00" version="3">opened</milestone>
          <milestone date="2019-03-12T21:14:32+00:00" version="3">submitted</milestone>
          <milestone date="2019-03-12T21:15:00+00:00" version="3">described</milestone>
          <milestone date="2019-03-12T21:17:27+00:00" version="3">published</milestone>
          <milestone date="2019-03-12T21:20:06+00:00" version="3">deposited</milestone>
          <milestone date="2019-03-12T21:20:46+00:00" version="3">accessioned</milestone>
          <milestone date="2019-03-12T22:28:46+00:00" version="4">opened</milestone>
          <milestone date="2019-03-12T22:28:56+00:00" version="4">submitted</milestone>
          <milestone date="2019-03-12T22:29:13+00:00" version="4">described</milestone>
          <milestone date="2019-03-12T22:31:49+00:00" version="4">published</milestone>
          <milestone date="2019-03-12T22:34:17+00:00" version="4">deposited</milestone>
          <milestone date="2019-03-12T22:34:57+00:00" version="4">accessioned</milestone>
        </lifecycle>
      XML
    end

    around do |example|
      WebMock.disable_net_connect!
      stub_request(:get, 'http://localhost:3001/dor/objects/druid:oo201oo0001/lifecycle').to_return(body: lifecycle)
      example.run
      WebMock.allow_net_connect!
    end

    it 'returns a hash' do
      expect(subject.keys).to eq %w[1 2 3 4]
      expect(subject['1']['accessioned'][:time]).to eq '2019-03-12T18:34:10+00:00'
    end
  end

  describe '#versions' do
    subject { presenter.versions }

    before do
      allow(item).to receive(:current_version).and_return(4)
    end

    it 'returns a hash' do
      expect(subject.keys).to eq %w[1 2 3 4]
      expect(subject['1']).to eq(desc: 'Initial Version', tag: '1.0.0')
    end
  end
end
