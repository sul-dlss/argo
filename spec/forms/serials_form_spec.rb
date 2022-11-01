# frozen_string_literal: true

require "rails_helper"

RSpec.describe SerialsForm do
  let(:instance) { described_class.new(cocina_item) }
  let(:druid) { "druid:bc123df4567" }
  let(:purl) { "https://purl.stanford.edu/bc123df4567" }
  let(:cocina_item) { build(:dro_with_metadata, id: druid).new(description:) }

  describe "loading from cocina" do
    context "when the number is before the part name" do
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {value: "My Serial", type: "main title"},
                {value: "7", type: "part number"},
                {value: "samurai", type: "part name"}
              ]
            }
          ],
          note: [
            {value: "1990", type: "date/sequential designation"}
          ],
          purl:
        }
      end

      it "loads the first part number" do
        expect(instance.part_number).to eq "7"
        expect(instance.part_name).to eq "samurai"
        expect(instance.part_number2).to be_nil
        expect(instance.sort_field).to eq "1990"
      end
    end

    context "when the number is after the part name" do
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {value: "My Serial", type: "main title"},
                {value: "samurai", type: "part name"},
                {value: "7", type: "part number"}
              ]
            }
          ],
          purl:
        }
      end

      it "loads the first part number" do
        expect(instance.part_number).to be_nil
        expect(instance.part_name).to eq "samurai"
        expect(instance.part_number2).to eq "7"
      end
    end

    context "when parallel title" do
      let(:description) do
        {
          title: [
            parallelValue: [
              {
                structuredValue: [
                  {value: "My Serial", type: "main title"},
                  {value: "7", type: "part number"},
                  {value: "samurai", type: "part name"}
                ]
              },
              {
                value: "parallel title"
              }
            ]
          ],
          note: [
            {value: "1990", type: "date/sequential designation"}
          ],
          purl:
        }
      end

      it "loads the first part number from the first parallel title" do
        expect(instance.part_number).to eq "7"
        expect(instance.part_name).to eq "samurai"
        expect(instance.part_number2).to be_nil
        expect(instance.sort_field).to eq "1990"
      end
    end

    context "when there is no part name" do
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                {value: "My Serial", type: "main title"},
                {value: "7", type: "part number"}
              ]
            }
          ],
          note: [
            {value: "1990", type: "date/sequential designation"}
          ],
          purl:
        }
      end

      it "loads the first part number" do
        expect(instance.part_number).to eq "7"
        expect(instance.part_number2).to be_nil
        expect(instance.sort_field).to eq "1990"
      end
    end
  end

  describe "validate and save" do
    context "when the initial title is unstructured" do
      let(:description) do
        {
          title: [{value: "My Serial"}],
          purl:
        }
      end
      let(:object_client) { instance_double(Dor::Services::Client::Object, update: true) }

      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      end

      context "when part_number is set" do
        let(:expected) do
          build(:dro_with_metadata, id: druid).new(description:
            {
              title: [
                {
                  structuredValue: [
                    {value: "My Serial", type: "main title"},
                    {value: "7", type: "part number"},
                    {value: "samurai", type: "part name"}
                  ]
                }
              ],
              note: [{value: "something", type: "date/sequential designation"}],
              purl:
            })
        end

        before do
          instance.validate({part_number: "7", part_name: "samurai", part_number2: "", sort_field: "something"})
          instance.save
        end

        it "serialized correctly" do
          expect(object_client).to have_received(:update).with(params: expected)
        end
      end

      context "when part_number2 is set" do
        let(:expected) do
          build(:dro_with_metadata, id: druid).new(description: {
            title: [
              {
                structuredValue: [
                  {value: "My Serial", type: "main title"},
                  {value: "samurai", type: "part name"},
                  {value: "7", type: "part number"}
                ]
              }
            ],
            note: [{value: "something", type: "date/sequential designation"}],
            purl:
          })
        end

        before do
          instance.validate({part_number: "", part_name: "samurai", part_number2: "7", sort_field: "something"})
          instance.save
        end

        it "serialized correctly" do
          expect(object_client).to have_received(:update).with(params: expected)
        end
      end
    end

    context "when the initial title is structured" do
      let(:description) do
        {
          title: [{
            structuredValue: [
              {type: "subtitle", value: "99"},
              {type: "main title", value: "Frog"}
            ]
          }],
          purl:
        }
      end
      let(:object_client) { instance_double(Dor::Services::Client::Object, update: true) }

      before do
        allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      end

      context "when part_number is set" do
        let(:expected) do
          build(:dro_with_metadata, id: druid).new(description: {
            title: [
              {
                structuredValue: [
                  {type: "subtitle", value: "99"},
                  {type: "main title", value: "Frog"},
                  {value: "7", type: "part number"},
                  {value: "samurai", type: "part name"}
                ]
              }
            ],
            note: [{value: "something", type: "date/sequential designation"}],
            purl:
          })
        end

        before do
          instance.validate({part_number: "7", part_name: "samurai", part_number2: "", sort_field: "something"})
          instance.save
        end

        it "serialized correctly" do
          expect(object_client).to have_received(:update).with(params: expected)
        end
      end

      context "when part_number2 is set" do
        let(:expected) do
          build(:dro_with_metadata, id: druid).new(description: {
            title: [
              {
                structuredValue: [
                  {type: "subtitle", value: "99"},
                  {type: "main title", value: "Frog"},
                  {value: "samurai", type: "part name"},
                  {value: "7", type: "part number"}
                ]
              }
            ],
            note: [{value: "something", type: "date/sequential designation"}],
            purl:
          })
        end

        before do
          instance.validate({part_number: "", part_name: "samurai", part_number2: "7", sort_field: "something"})
          instance.save
        end

        it "serialized correctly" do
          expect(object_client).to have_received(:update).with(params: expected)
        end
      end
    end
  end

  context "when parallel title" do
    let(:description) do
      {
        title: [
          {
            parallelValue: [
              {
                value: "My Serial"
              },
              {
                value: "My Parallel Serial"
              }
            ]
          }
        ],
        purl:
      }
    end
    let(:object_client) { instance_double(Dor::Services::Client::Object, update: true) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    context "when part_number is set" do
      let(:expected) do
        build(:dro_with_metadata, id: druid).new(description:
          {
            title: [
              {
                parallelValue: [
                  {
                    structuredValue: [
                      {value: "My Serial", type: "main title"},
                      {value: "7", type: "part number"},
                      {value: "samurai", type: "part name"}
                    ]
                  },
                  {
                    value: "My Parallel Serial"
                  }
                ]
              }
            ],
            note: [{value: "something", type: "date/sequential designation"}],
            purl:
          })
      end

      before do
        instance.validate({part_number: "7", part_name: "samurai", part_number2: "", sort_field: "something"})
        instance.save
      end

      it "serialized correctly to first parallel title" do
        expect(object_client).to have_received(:update).with(params: expected)
      end
    end

    context "when catalog links present" do
      let(:cocina_item) { build(:dro_with_metadata, id: druid, catkeys: ["6671606"]) }

      let(:expected) do
        build(:dro_with_metadata, id: druid).new(
          description: {
            title: [
              {
                structuredValue: [
                  {value: "factory DRO title", type: "main title"}
                ]
              }
            ],
            purl: "https://purl.stanford.edu/bc123df4567"
          },
          identification: {
            catalogLinks: [
              {catalog: "symphony", refresh: false, catalogRecordId: "6671606"}
            ],
            sourceId: "sul:1234"
          }
        )
      end

      before do
        instance.validate({part_number: "", part_name: "", part_number2: "", sort_field: ""})
        instance.save
      end

      it "sets refresh to false" do
        expect(object_client).to have_received(:update).with(params: expected)
      end
    end
  end
end
