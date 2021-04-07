# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::ExternalFileComponent, type: :component do
  let(:component) { described_class.new(external_file: id) }
  let(:rendered) { render_inline(component) }
  let(:id) { 'kg748gk9672_1/1642a.jp2' }

  it 'renders the component' do
    expect(rendered.css('li').to_html)
      .to include '1642a.jp2'

    expect(rendered.css('li a').to_html)
      .to eq '<a href="/view/druid:kg748gk9672">druid:kg748gk9672</a>'

    expect(rendered.css('li').to_html)
      .to include "resource 'kg748gk9672_1'"
  end
end
