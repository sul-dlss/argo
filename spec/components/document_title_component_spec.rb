# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DocumentTitleComponent, type: :component do
  subject(:component) { described_class.new(presenter:, document:) }

  let(:ability_mock) { instance_double(Ability, can?: true) }
  let(:document) do
    instance_double(
      SolrDocument,
      id: 'druid:ab123cd3445',
      admin_policy?: admin_policy,
      virtual_object?: virtual_object,
      object_type:
    )
  end
  let(:presenter) { instance_double(ArgoShowPresenter, document:, cocina: nil) }
  let(:rendered) { render_inline(component) }

  before do
    allow(component).to receive(:helpers).and_return(ability_mock)
    allow(component).to receive(:title).and_return('Dummy Title')
  end

  context 'with an APO' do
    let(:admin_policy) { true }
    let(:virtual_object) { false }
    let(:object_type) { 'adminPolicy' }

    it 'renders the expected object type label' do
      expect(rendered.css('div.object-type').first.text.strip).to eq('apo')
    end

    it 'renders the expected object type class' do
      expect(rendered.css('div.object-type').first.classes).to include('object-type-apo')
    end
  end

  context 'with an agreement' do
    let(:admin_policy) { false }
    let(:virtual_object) { false }
    let(:object_type) { 'agreement' }

    it 'renders the expected object type label' do
      expect(rendered.css('div.object-type').first.text.strip).to eq('agreement')
    end

    it 'renders the expected object type class' do
      expect(rendered.css('div.object-type').first.classes).to include('object-type-agreement')
    end
  end

  context 'with a collection' do
    let(:admin_policy) { false }
    let(:virtual_object) { false }
    let(:object_type) { 'collection' }

    it 'renders the expected object type label' do
      expect(rendered.css('div.object-type').first.text.strip).to eq('collection')
    end

    it 'renders the expected object type class' do
      expect(rendered.css('div.object-type').first.classes).to include('object-type-collection')
    end
  end

  context 'with an item' do
    let(:admin_policy) { false }
    let(:virtual_object) { false }
    let(:object_type) { 'item' }

    it 'renders the expected object type label' do
      expect(rendered.css('div.object-type').first.text.strip).to eq('item')
    end

    it 'renders the expected object type class' do
      expect(rendered.css('div.object-type').first.classes).to include('object-type-item')
    end
  end

  context 'with a virtual object' do
    let(:admin_policy) { false }
    let(:virtual_object) { true }
    let(:object_type) { 'item' }

    it 'renders the expected object type label' do
      expect(rendered.css('div.object-type').first.text.strip).to eq('virtual object')
    end

    it 'renders the expected object type class' do
      expect(rendered.css('div.object-type').first.classes).to include('object-type-virtual-object')
    end
  end
end
