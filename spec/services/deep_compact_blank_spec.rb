# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeepCompactBlank do
  subject(:compacted) { described_class.run(enumerable:) }

  describe ".run" do
    context "with a string" do
      let(:enumerable) { "foobar" }

      it "returns the value unchanged" do
        expect(compacted).to eq(enumerable)
      end
    end

    context "with an empty array" do
      let(:enumerable) { [] }

      it "returns the value unchanged" do
        expect(compacted).to eq(enumerable)
      end
    end

    context "with an empty hash" do
      let(:enumerable) { {} }

      it "returns the value unchanged" do
        expect(compacted).to eq(enumerable)
      end
    end

    context "with deeply nested structure of hashes and arrays" do
      let(:enumerable) do
        {
          foo: "bar",
          compact_me: [],
          keep_me: {
            compact_me_too: [],
            another_keeper: [
              {},
              {
                title: "awesome",
                nope: [],
                container: [
                  ok: "stuff",
                  byebye: []
                ]
              }
            ]
          }
        }
      end

      it "removes all empty hashes and arrays" do
        expect(compacted).to eq(foo: "bar",
          keep_me: {
            another_keeper: [
              {
                title: "awesome",
                container: [
                  ok: "stuff"
                ]
              }
            ]
          })
      end
    end
  end
end
