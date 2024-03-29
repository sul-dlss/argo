# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Show::Apo::RolesComponent, type: :component do
  let(:presenter) { instance_double(ArgoShowPresenter, cocina: apo) }
  let(:component) { described_class.new(presenter:) }
  let(:rendered) { render_inline(component) }

  let(:apo) do
    build(:admin_policy).new(administrative:)
  end

  let(:administrative) do
    {
      hasAdminPolicy: 'druid:xx666zz7777',
      hasAgreement: 'druid:hp308wm0436',
      accessTemplate: { view: 'world', download: 'world' },
      roles: [
        {
          members: [
            { identifier: 'dlss:developers', type: 'workgroup' },
            { identifier: 'dlss:pmag-staff', type: 'workgroup' },
            { identifier: 'dlss:smpl-staff', type: 'workgroup' },
            { identifier: 'dlss:dpg-staff', type: 'workgroup' },
            { identifier: 'dlss:argo-access-spec', type: 'workgroup' }
          ],
          name: 'dor-apo-manager'
        }
      ]
    }
  end

  it 'has the value' do
    expect(rendered.css('tbody tr').count).to eq 5
    expect(rendered.css('tbody tr td:first-child').map(&:text)).to eq %w[developers pmag-staff smpl-staff dpg-staff
                                                                         argo-access-spec]
  end
end
