# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ontology do
  describe 'Term' do
    subject(:term) do
      described_class::Term.new(key: 'foo', uri: 'http://example.com/foo', human_readable: 'Foo is a placeholder')
    end

    describe '#key' do
      subject { term.key }

      it { is_expected.to eq 'foo' }
    end

    describe '#label' do
      subject { term.label }

      it { is_expected.to eq 'Foo is a placeholder' }
    end

    describe '#uri' do
      subject { term.uri }

      it { is_expected.to eq 'http://example.com/foo' }
    end

    describe '#deprecation_warning' do
      subject { term.deprecation_warning }

      it { is_expected.to be_nil }
    end
  end
end
