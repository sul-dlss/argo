require 'spec_helper'

describe 'items/_button_link_list.html.erb' do
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
        url: 'http://www.example.com/ajax',
        ajax_modal: true
      }
    ]
  end
  it 'should contain button group, with specific buttons' do
    render 'items/button_link_list', buttons: buttons
    expect(rendered).to have_css '.btn-group-vertical.argo-show-btn-group'
    expect(rendered).to have_css 'a', count: buttons.length
    expect(rendered).to have_css 'a[href="http://www.example.com/click"]', text: 'Click me'
    expect(rendered).to have_css 'a[href="http://www.example.com/confirm"][data-confirm="true"]', text: 'Confirm me'
    expect(rendered).to have_css 'a[href="http://www.example.com/ajax"][data-ajax-modal="trigger"]', text: 'Ajax me'
  end
end
