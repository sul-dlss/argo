# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Set content type for an item" do
  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  let(:druid) { "druid:bc123df4567" }
  let(:user) { create(:user) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
  let(:content_type) { Cocina::Models::ObjectType.image }
  let(:cocina_model) do
    build(:dro_with_metadata, id: druid, type: content_type).new(structural:)
  end
  let(:contains) do
    [
      Cocina::Models::FileSet.new(
        externalIdentifier: "bc123df4567_2",
        type: Cocina::Models::FileSetType.document,
        label: "document files",
        version: 1,
        structural: Cocina::Models::FileSetStructural.new(
          contains: [
            Cocina::Models::File.new(
              externalIdentifier: "bc123df4567.pdf",
              type: Cocina::Models::ObjectType.file,
              label: "the PDF",
              filename: "bc123df4567.pdf",
              version: 1
            )
          ]
        )
      ),
      Cocina::Models::FileSet.new(
        externalIdentifier: "bc123df4567_2",
        type: Cocina::Models::FileSetType.image,
        label: "image files",
        version: 1,
        structural: Cocina::Models::FileSetStructural.new(
          contains: [
            Cocina::Models::File.new(
              externalIdentifier: "bc123df4567.png",
              type: Cocina::Models::ObjectType.file,
              label: "the PNG",
              filename: "bc123df4567.png",
              version: 1
            )
          ]
        )
      )
    ]
  end
  let(:structural) do
    Cocina::Models::DROStructural.new(
      contains:
    )
  end

  describe "show the form" do
    before do
      sign_in user, groups: ["sdr:manager-role"]
    end

    let(:content_type) { Cocina::Models::ObjectType.image }

    it "is successful" do
      get "/items/#{druid}/content_type/edit"
      expect(response).to be_successful
      expect(response.body).to include("Set content type")
    end
  end

  describe "save the updated value" do
    before do
      allow(StateService).to receive(:new).and_return(state_service)
    end

    let(:state_service) { instance_double(StateService, allows_modification?: true) }

    context "with access" do
      before do
        sign_in user, groups: ["sdr:administrator-role"]
      end

      it "is successful at changing the content type to media" do
        patch "/items/#{druid}/content_type",
          params: {content_type: {new_content_type: Cocina::Models::ObjectType.media}}
        expect(response).to redirect_to solr_document_path(druid)
        expect(object_client).to have_received(:update)
          .with(params: cocina_object_with_types(content_type: Cocina::Models::ObjectType.media, viewing_direction: nil))
          .once
      end

      it "is successful at changing the content type to book (ltr)" do
        patch "/items/#{druid}/content_type",
          params: {content_type: {new_content_type: Cocina::Models::ObjectType.book, viewing_direction: "left-to-right"}}

        expect(response).to redirect_to solr_document_path(druid)
        expect(object_client).to have_received(:update)
          .with(params: cocina_object_with_types(content_type: Cocina::Models::ObjectType.book, viewing_direction: "left-to-right"))
          .once
      end

      it "is successful at changing the content type to book (rtl)" do
        patch "/items/#{druid}/content_type",
          params: {content_type: {new_content_type: Cocina::Models::ObjectType.book, viewing_direction: "right-to-left"}}

        expect(response).to redirect_to solr_document_path(druid)
        expect(object_client).to have_received(:update)
          .with(params: cocina_object_with_types(content_type: Cocina::Models::ObjectType.book, viewing_direction: "right-to-left"))
          .once
      end

      it "is successful at changing the resource type" do
        patch "/items/#{druid}/content_type",
          params: {content_type: {old_resource_type: Cocina::Models::FileSetType.document, new_resource_type: Cocina::Models::FileSetType.file,
                                  new_content_type: Cocina::Models::ObjectType.image}}

        expect(response).to redirect_to solr_document_path(druid)
        expect(object_client).to have_received(:update)
          .with(
            params: cocina_object_with_types(
              resource_types: [Cocina::Models::FileSetType.file, Cocina::Models::FileSetType.image],
              without_order: true
            )
          ).once
      end

      context "when the values don't change from the original" do
        it "is successful" do
          patch "/items/#{druid}/content_type",
            params: {content_type: {new_content_type: Cocina::Models::ObjectType.image,
                                    old_resource_type: Cocina::Models::FileSetType.file,
                                    new_resource_type: Cocina::Models::FileSetType.document}}

          expect(response).to redirect_to solr_document_path(druid)
          expect(object_client).to have_received(:update)
            .with(
              params: cocina_object_with_types(
                content_type: Cocina::Models::ObjectType.image,
                resource_types: [Cocina::Models::FileSetType.document, Cocina::Models::FileSetType.image]
              )
            )
        end
      end

      context "when the new resource type is none" do
        it "doesn't change the value" do
          patch "/items/#{druid}/content_type",
            params: {content_type: {new_content_type: Cocina::Models::ObjectType.image,
                                    old_resource_type: Cocina::Models::FileSetType.document,
                                    new_resource_type: ""}}

          expect(response).to redirect_to solr_document_path(druid)
          expect(object_client).to have_received(:update)
            .with(
              params: cocina_object_with_types(
                content_type: Cocina::Models::ObjectType.image,
                resource_types: [Cocina::Models::FileSetType.document, Cocina::Models::FileSetType.image]
              )
            )
        end
      end

      context "without structural metadata" do
        let(:structural) { Cocina::Models::DROStructural.new({}) }

        it "changes the content type only" do
          patch "/items/#{druid}/content_type",
            params: {content_type: {new_content_type: Cocina::Models::ObjectType.media}}

          expect(response).to redirect_to solr_document_path(druid)
          expect(object_client).to have_received(:update)
            .with(params: cocina_object_with_types(content_type: Cocina::Models::ObjectType.media))
        end
      end

      context "when modification not allowed" do
        let(:state_service) { instance_double(StateService, allows_modification?: false) }

        it "is forbidden" do
          patch "/items/#{druid}/content_type",
            params: {content_type: {new_content_type: Cocina::Models::ObjectType.media}}

          expect(response).to redirect_to("/view/#{druid}")
          expect(flash[:error]).to eq "Object cannot be modified in its current state."
        end
      end

      context "with an invalid content_type" do
        it "is forbidden" do
          patch "/items/#{druid}/content_type",
            params: {content_type: {new_content_type: "https://cocina.sul.stanford.edu/models/frog"}}

          expect(response).to be_forbidden
          expect(response.body).to eq "New content type is not included in the list"
        end
      end
    end

    context "without access" do
      before do
        sign_in user, groups: []
      end

      it "is forbidden" do
        patch "/items/#{druid}/content_type", params: {content_type: {new_content_type: Cocina::Models::ObjectType.media}}

        expect(response).to be_forbidden
        expect(response.body).to eq("forbidden")
      end
    end
  end
end
