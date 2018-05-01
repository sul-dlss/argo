require 'spec_helper'
require 'argo/htaccess_directives'

RSpec.describe Argo::HtaccessDirectives do
  describe '#write' do
    subject do
      described_class.write(groups)
    end

    context 'when workgroups are provided' do
      let(:groups) do
        ['workgroup:one', 'workgroup:two', 'bad:nope']
      end

      it 'writes only the prefixed workgroups' do
        expect(subject).to include 'Require shib-attr eduPersonEntitlement one'
        expect(subject).to include 'Require shib-attr eduPersonEntitlement two'
        expect(subject).not_to include 'nope'
      end
    end

    context 'when no workgroups are provided' do
      let(:groups) do
        []
      end

      it 'writes only the prefixed workgroups' do
        expect(subject).to eq ''
      end
    end
  end
end
