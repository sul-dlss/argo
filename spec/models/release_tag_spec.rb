# frozen_string_literal: true

require 'spec_helper'

describe ReleaseTag do
  describe '#initialize' do
    subject do
      described_class.new(
        to: 'SearchWorks',
        what: 'self',
        when_time: '2016-09-13T20:00:00.000Z',
        who: 'esnowden',
        release: 'true'
      )
    end
    it 'casts a Boolean string to a Boolean' do
      expect(subject.release).to eq true
    end
    it 'returns itself if a string is not a boolean' do
      expect(subject.send(:string_to_boolean, 'yolo')).to eq 'yolo'
    end
    it 'responds to needed public accessors' do
      [:to, :what, :when, :who, :release].each do |accessor|
        expect(subject).to respond_to(accessor)
      end
    end
  end
  describe '.from_tag' do
    let(:tag) { '<release to="SearchWorks" what="self" when="2016-09-13T20:00:00.000Z" who="esnowden">true</release>' }
    let(:element) { Nokogiri::XML(tag).xpath('//release').first }
    subject { described_class.from_tag(element) }
    it 'creates a ReleaseTag putting the attributes in the correct places' do
      expect(subject).to be_an described_class
      expect(subject.to).to eq 'SearchWorks'
      expect(subject.what).to eq 'self'
      expect(subject.when).to eq '2016-09-13T20:00:00.000Z'
      expect(subject.who).to eq 'esnowden'
      expect(subject.release).to eq true
    end
  end
end
