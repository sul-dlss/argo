# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Contents::ResourceComponent, type: :component do
  let(:component) { described_class.new(resource: resource, resource_counter: 1, object_id: 'druid:kb487gt5106', viewable: true) }
  let(:rendered) { render_inline(component) }
  let(:resource) { build(:file_set, type: type) }

  context 'with an image' do
    let(:type) { Cocina::Models::FileSetType.image }

    it 'renders the component' do
      expect(rendered.to_html).to include 'Type'
      expect(rendered.to_html).to include 'Height'
      expect(rendered.to_html).to include 'Width'
    end
  end

  context 'when fileset is not an image' do
    let(:type) { Cocina::Models::FileSetType.file }

    it 'height column does not display' do
      expect(rendered.to_html).not_to include 'Height'
    end
  end
end
