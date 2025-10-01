# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmbargoForm do
  let(:instance) { described_class.new(cocina_object, **params) }
  let(:cocina_object) do
    cocina_object = Cocina::Models::DRO.new(props)
    Cocina::Models.with_metadata(cocina_object, 'abc123')
  end
  let(:props) do
    {
      externalIdentifier: 'druid:bc234fg5678',
      type: Cocina::Models::ObjectType.image,
      label: 'Test DRO',
      version: 1,
      description: {
        title: [{ value: 'Test DRO' }],
        purl: 'https://purl.stanford.edu/bc234fg5678'
      },
      access:,
      identification: { sourceId: 'sul:1234' },
      structural: {},
      administrative: {
        hasAdminPolicy: 'druid:hv992ry2431'
      }
    }
  end
  let(:access) { { view: 'stanford', download: 'stanford' } }
  let(:releaseDate) { DateTime.now + 1.year } # rubocop:disable RSpec/VariableName
  let(:release_date) { releaseDate.to_date.to_fs(:default) }
  let(:params) { {} }

  before do
    allow(Repository).to receive(:store).and_return(true)
  end

  it 'initializes with a cocina object' do
    expect(instance.model).to eq(cocina_object)
  end

  describe 'with an embargo' do
    let(:access) { { view: 'stanford', download: 'stanford', embargo: } }

    describe 'that is unchanged' do
      let(:embargo) { { view: 'world', download: 'world', releaseDate: } }

      it 'the form is valid' do
        expect(instance).to be_valid
      end
    end

    describe 'and world/world is changed' do
      let(:embargo) { { view: 'world', download: 'world', releaseDate: } }

      describe 'to citation-only' do
        let(:params) { { view_access: 'citation-only', release_date: } }
        let(:embargo_params) { { view: 'citation-only', download: 'none', releaseDate: release_date, location: nil, controlledDigitalLending: false } }

        it 'the embargo_params are updated and the form is valid' do
          instance.validate(params)
          expect(instance.embargo_params).to eq(embargo_params)
          expect(instance.save).to be_truthy
          expect(instance).to be_valid
        end
      end

      describe 'to dark' do
        let(:params) { { view_access: 'dark', release_date: } }
        let(:embargo_params) { { view: 'dark', download: 'none', releaseDate: release_date, location: nil, controlledDigitalLending: false } }

        it 'the embargo_params are updated and the form is valid' do
          instance.validate(params)
          expect(instance.embargo_params).to eq(embargo_params)
          expect(instance.save).to be_truthy
          expect(instance).to be_valid
        end
      end
    end

    describe 'that is location-based' do
      let(:embargo) { { view: 'location-based', download: 'location-based', location: 'spec', releaseDate: } }

      describe 'and is changed to world/world' do
        let(:params) { { view_access: 'world', download_access: 'world', release_date: } }
        let(:embargo_params) { { view: 'world', download: 'world', releaseDate: release_date, location: nil, controlledDigitalLending: false } }

        it 'the embargo_params are updated and the form is valid' do
          instance.validate(params)
          expect(instance.embargo_params).to eq(embargo_params)
          expect(instance.save).to be_truthy
          expect(instance).to be_valid
        end
      end

      describe 'and is changed to citation-only but download is unchanged' do
        let(:params) { { view_access: 'citation-only', download_access: 'location-based', access_location: 'spec', release_date: } }
        let(:embargo_params) { { view: 'citation-only', download: 'none', releaseDate: release_date, location: nil, controlledDigitalLending: false } }

        it 'the embargo_params are updated to a valid combination and the form is valid' do
          instance.validate(params)
          expect(instance.embargo_params).to eq(embargo_params)
          expect(instance.save).to be_truthy
          expect(instance).to be_valid
        end
      end
    end
  end
end
