# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TechmdComponent, type: :component do
  include Dry::Monads[:result]

  subject(:component) { described_class.new(result: result) }

  let(:rendered) { render_inline(component) }

  context 'with a failure' do
    let(:result) { Failure('it borken!') }

    it 'renders the error message' do
      expect(rendered.css('p').to_html).to include('it borken!')
    end
  end

  context 'with no results' do
    let(:result) { Success([]) }

    it 'renders the error message' do
      expect(rendered.css('p').to_html).to include('Technical Metadata not available')
    end
  end

  context 'with results' do
    let(:result) { Success(['filename' => 'sunburst.png']) }

    it 'renders something useful' do
      expect(rendered.css('.file').to_html).to include('sunburst.png')
    end
  end
end
