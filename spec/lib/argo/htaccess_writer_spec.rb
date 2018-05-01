require 'spec_helper'
require 'argo/htaccess_writer'

RSpec.describe Argo::HtaccessWriter do
  describe '#write' do
    let(:groups) { [] }
    let(:file_path) { described_class::FILE }

    before do
      File.unlink(file_path) if File.exist?(file_path)
    end

    subject do
      described_class.write(groups, directive_writer: writer)
    end

    context 'when workgroups are provided' do
      let(:writer) { double(write: 'stuff') }

      it 'writes the htaccess file' do
        expect(writer).to receive(:write).with(groups)
        subject
        expect(File).to exist(file_path)
      end
    end

    context 'when no workgroups are provided' do
      let(:writer) { double(write: '') }

      it 'does not write the htaccess file' do
        expect(writer).to receive(:write).with(groups)
        subject
        expect(File).not_to exist(file_path)
      end
    end
  end
end
