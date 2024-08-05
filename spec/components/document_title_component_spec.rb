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
  let(:presenter) do
    instance_double(ArgoShowPresenter, document:, cocina: nil,
                                       user_version_view: user_version,
                                       head_user_version:,
                                       head_user_version_view?: user_version.present? && user_version == head_user_version,
                                       version_view: version,
                                       current_version:,
                                       current_version_view?: version.present? && version == current_version,
                                       version_or_user_version_view?: version.present? || user_version.present?)
  end
  let(:user_version) { nil }
  let(:head_user_version) { nil }
  let(:version) { nil }
  let(:current_version) { nil }
  let(:rendered) { render_inline(component) }

  before do
    allow(component).to receive_messages(helpers: ability_mock, title: 'Dummy Title')
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

    context 'with a user version' do
      let(:user_version) { '2' }
      let(:head_user_version) { '3' }

      it 'renders the expected user version label' do
        expect(rendered.content).to include('You are viewing an older version.')
      end
    end

    context 'with a head user version' do
      let(:user_version) { '2' }
      let(:head_user_version) { '2' }

      it 'renders the expected user version label' do
        expect(rendered.content).to include('You are viewing the latest version.')
      end
    end

    context 'with a version' do
      let(:version) { '2' }
      let(:current_version) { '3' }

      it 'renders the expected version label' do
        expect(rendered.content).to include('You are viewing an older version.')
      end
    end

    context 'with a current version' do
      let(:version) { '2' }
      let(:current_version) { '2' }

      it 'renders the expected version label' do
        expect(rendered.content).to include('You are viewing the latest version.')
      end
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
