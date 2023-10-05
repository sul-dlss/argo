# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ModsValidator do
  subject(:validate) { described_class.validate(doc) }

  let(:doc) { Nokogiri::XML(xml) }

  context 'with an invalid doc' do
    let(:xml) do
      <<~XML
        <mods xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://www.loc.gov/mods/v3" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        //id.loc.gov/authorities/subjects/sh85106971 authority="Soviet Union" authorityURI="naf" valueURI="http://id.loc.gov/authorities/names" encoding="" point=""&gt;geographic
        </mods>
      XML
    end

    it { is_expected.to be_present }
  end

  context 'with an valid doc' do
    let(:xml) do
      <<~XML
        <mods xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://www.loc.gov/mods/v3" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
              <titleInfo>
                <title>Oral history with Jakob Spielmann</title>
              </titleInfo>
        </mods>
      XML
    end

    it { is_expected.to be_empty }
  end
end
