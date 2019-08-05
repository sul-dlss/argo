# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArgoHelper, type: :helper do
  describe 'render_facet_value' do
    it 'does not override Blacklight version' do
      expect(helper).to respond_to(:render_facet_value)
      expect(helper.method(:render_facet_value).owner).to eq(Blacklight::FacetsHelperBehavior)
    end
  end
end
