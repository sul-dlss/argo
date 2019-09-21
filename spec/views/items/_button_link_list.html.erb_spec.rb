# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'items/_button_link_list.html.erb' do
  let(:buttons) do
    [
      {
        label: 'Click me',
        url: 'http://www.example.com/click'
      },
      {
        label: 'Confirm me',
        url: 'http://www.example.com/confirm',
        confirm: true
      },
      {
        label: 'Ajax me',
        url: 'http://www.example.com/ajax'
      },
      {
        label: 'Check me',
        url: 'http://www.example.com/check',
        check_url: workflow_service_closeable_path('abc:123')
      },
      {
        label: 'Disable me',
        url: 'http://www.example.com/check',
        disabled: true
      }
    ]
  end

  it 'contains button group, with specific buttons' do
    render 'items/button_link_list', buttons: buttons
    expect(rendered).to have_css '.btn-group-vertical.argo-show-btn-group'
    expect(rendered).to have_css 'a', count: buttons.length
    expect(rendered).to have_css 'a[href="http://www.example.com/click"]', text: 'Click me'
    expect(rendered).to have_css 'a[href="http://www.example.com/confirm"][data-confirm="true"]', text: 'Confirm me'
    expect(rendered).to have_css 'a[href="http://www.example.com/ajax"][data-blacklight-modal="trigger"]', text: 'Ajax me'
    expect(rendered).to have_css 'a.disabled[href="http://www.example.com/check"][data-check-url="/workflow_service/abc:123/closeable"]', text: 'Check me'
    expect(rendered).to have_css 'a.disabled[href="http://www.example.com/check"]', text: 'Disable me'
  end
end
