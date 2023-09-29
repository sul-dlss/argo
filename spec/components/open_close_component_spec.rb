# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenCloseComponent, type: :component do
  let(:component) do
    described_class.new(id: item_id)
  end

  let(:rendered) { render_inline(component) }
  let(:item_id) { 'druid:kv840xx0000' }

  it 'renders an eager loading turbo frame' do
    expect(rendered.css('turbo-frame').attribute('src').value).to eq '/workflow_service/druid:kv840xx0000/lock'
  end
end
