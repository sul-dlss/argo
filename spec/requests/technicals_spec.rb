# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Technicals', type: :request do
  include Dry::Monads[:result]

  before do
    allow(Argo.verifier).to receive(:verified).and_return({ key: 'druid:kv840xx0000' })
    allow(TechmdService).to receive(:techmd_for).and_return(result)
    sign_in build(:user), groups: []
  end

  let(:rendered) do
    Capybara::Node::Simple.new(response.body)
  end

  context 'with a failure' do
    let(:result) { Failure('it borken!') }

    it 'renders the error message' do
      get '/items/skret-t0k3n/technical'
      expect(rendered.find_css('p').to_html).to include('it borken!')
    end
  end

  context 'with no results' do
    let(:result) { Success([]) }

    it 'renders the error message' do
      get '/items/skret-t0k3n/technical'
      expect(rendered.find_css('p').to_html).to include('Technical Metadata not available')
    end
  end

  context 'with results' do
    let(:result) { Success(['filename' => 'sunburst.png']) }

    it 'renders something useful' do
      get '/items/skret-t0k3n/technical'
      expect(rendered.find_css('.file').to_html).to include('sunburst.png')
    end
  end
end
