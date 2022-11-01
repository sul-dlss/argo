# frozen_string_literal: true

require "rails_helper"

RSpec.describe ItemsHelper, type: :helper do
  describe "#stacks_url_full_size" do
    subject { helper.stacks_url_full_size("druid:999", "foo/bar.txt") }

    it { is_expected.to eq "https://stacks-test.stanford.edu/file/druid:999/foo%2Fbar.txt" }
  end

  describe "#license_options" do
    subject(:options) { helper.license_options }

    it "is a list with url and label" do
      expect(options).to include(
        [
          "CC Attribution-ShareAlike 4.0 International",
          "https://creativecommons.org/licenses/by-sa/4.0/legalcode"
        ]
      )
    end
  end
end
