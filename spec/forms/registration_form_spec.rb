# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegistrationForm do
  let(:instance) { described_class.new(ActionController::Parameters.new(params)) }

  describe '#cocina_model' do
    subject(:cocina_model) { instance.cocina_model }

    let(:required_params) do
      {
        other_id: 'label:',
        source_id: 'foo:bar',
        admin_policy: 'druid:hv992yv2222',
        label: 'test parameters for registration',
        tag: ['Process : Content Type : File'],
        rights: 'default'
      }
    end

    context 'when project is an empty string' do
      let(:params) do
        required_params.merge(project: '')
      end

      it 'does not have a project' do
        expect(cocina_model.administrative.partOfProject).to be_nil
      end
    end

    context 'when barcode is nil' do
      let(:params) do
        required_params.merge(barcode: nil)
      end

      it 'does not have a barcode' do
        expect(cocina_model.identification.barcode).to be_nil
      end
    end

    context 'when barcode is set and valid' do
      let(:barcode) { '20503740296' }
      let(:params) do
        required_params.merge(barcode_id: barcode)
      end

      it 'has a barcode' do
        expect(cocina_model.identification.barcode).to eq(barcode)
      end
    end

    context 'when barcode is set and invalid' do
      let(:barcode) { 'foobar' }
      let(:params) do
        required_params.merge(barcode_id: barcode)
      end

      it 'raises a cocina validation error' do
        expect { cocina_model.identification.barcode }.to raise_error(
          Cocina::Models::ValidationError,
          %r{"#{barcode}" isn't one of in #/components/schemas/Barcode}
        )
      end
    end
  end
end
