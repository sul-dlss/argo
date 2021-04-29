# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ManageRelease::CollectionFormComponent, type: :component do
  subject(:component) { described_class.new(form: form, current_user: build(:user)) }

  let(:form) { ActionView::Helpers::FormBuilder.new(nil, nil, controller.view_context, {}) }
  let(:rendered) { render_inline(component) }

  it 'renders the options' do
    expect(rendered.css('label').to_html).to include(
      'This collection and all its members*',
      'Only this collection description but not any of its members',
      'Release it',
      'Do not release it (withdraw)'
    )
  end
end