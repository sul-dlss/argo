# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::ConstituentComponent, type: :component do
  let(:component) { described_class.new(druid: id) }
  let(:rendered) { render_inline(component) }
  let(:id) { 'druid:bf746ns6287' }

  it 'renders the component' do
    expect(rendered.css('li').to_html)
      .to include 'druid:bf746ns6287'

    expect(rendered.css('li a').to_html)
      .to eq '<a target="_top" href="/view/druid:bf746ns6287">druid:bf746ns6287</a>'
  end
end
