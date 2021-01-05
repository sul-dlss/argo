# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegistrationForm do
  let(:instance) { described_class.new(ActionController::Parameters.new(params)) }

  describe '#cocina_model' do
    subject(:cocina_model) { instance.cocina_model }

    context 'when project is an empty string' do
      let(:params) do
        {
          other_id: 'label:',
          source_id: 'foo:bar',
          admin_policy: 'druid:hv992yv2222',
          label: 'test parameters for registration',
          tag: ['Process : Content Type : File'],
          rights: 'default',
          project: ''
        }
      end

      it 'does not have a project' do
        expect(cocina_model.administrative.partOfProject).to be_nil
      end
    end
  end
end
