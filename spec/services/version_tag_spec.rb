# frozen_string_literal: true

require "rails_helper"

RSpec.describe VersionTag do
  describe ".parse" do
    subject(:instance) { described_class.parse(version_tag) }

    context "when tag matches valid pattern" do
      let(:version_tag) { "1.2.3" }

      it { is_expected.to be_a(described_class) }
    end

    context "when tag does not match valid pattern" do
      let(:version_tag) { "foobar" }

      it { is_expected.to be_nil }
    end
  end

  describe "#new" do
    subject(:instance) { described_class.new("1", "2", "3") }

    it "has attribute `major`" do
      expect(instance.major).to eq(1)
    end

    it "has attribute `minor`" do
      expect(instance.minor).to eq(2)
    end

    it "has attribute `admin`" do
      expect(instance.admin).to eq(3)
    end
  end
end
