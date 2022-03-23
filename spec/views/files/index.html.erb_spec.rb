# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'files/index' do
  before do
    @file = build(:managed_file)
    @has_been_accessioned = true
    @last_accessioned_version = '7'
    params[:id] = 'M1090_S15_B01_F07_0106.jp2'
    params[:item_id] = 'druid:rn653dy9317'
    render
  end

  it 'renders the partial content' do
    expect(rendered).to have_content 'Stacks'
    expect(rendered).to have_content 'Preservation'
  end
end
