# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowXmlPresenter do
  subject(:presenter) do
    described_class.new(xml: xml)
  end

  describe '#pretty_xml' do
    subject { presenter.pretty_xml }

    let(:xml) do
      '<?xml version="1.0" encoding="UTF-8"?>
        <workflow repository="dor" objectId="druid:bc123df4567" id="accessionWF">
        </workflow>'
    end

    it { is_expected.to be_html_safe }
  end
end
