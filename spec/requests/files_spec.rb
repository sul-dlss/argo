# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Files", type: :request do
  let(:druid) { "druid:bc123df4567" }
  let(:user) { create(:user) }
  let(:cocina_model) do
    instance_double(Cocina::Models::DROWithMetadata, externalIdentifier: druid, structural:)
  end
  let(:file_set) do
    instance_double(Cocina::Models::FileSet, structural: fs_structural)
  end
  let(:structural) do
    instance_double(Cocina::Models::DROStructural, contains: [file_set])
  end
  let(:fs_structural) do
    instance_double(Cocina::Models::FileSetStructural, contains: [file])
  end
  let(:file) do
    Cocina::Models::File.new(
      type: Cocina::Models::ObjectType.file,
      externalIdentifier: "druid:rn653dy9317/M1090_S15_B01_F07_0106.jp2",
      label: "M1090_S15_B01_F07_0106.jp2",
      filename: "M1090_S15_B01_F07_0106.jp2",
      size: 3_305_991,
      version: 4,
      hasMimeType: "image/jp2",
      hasMessageDigests: [
        {
          type: "sha1",
          digest: "fd28e74b3139b04a0e5c5c3d3263598f629f8967"
        },
        {
          type: "md5",
          digest: "244cbb3960407f59ac77a916870e0502"
        }
      ],
      access: {
        view: "world",
        download: "world"
      },
      administrative: {
        publish: true,
        sdrPreserve: true,
        shelve: true
      },
      presentation: {
        height: 3426,
        width: 5102
      }
    )
  end
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    sign_in user
  end

  describe "download from preservation" do
    context "when they have manage access" do
      let(:mock_file_name) { "preserved file.txt" }
      let(:mock_version) { "2" }
      let(:mock_content) { "preserved file content" }

      before do
        sign_in user, groups: ["sdr:administrator-role"]

        allow(Preservation::Client.objects).to receive(:content)
      end

      it "returns a response with the preserved file content as the body and the right headers" do
        last_modified_lower_bound = Time.now.utc.rfc2822
        get "/items/#{druid}/files/preserved%20file.txt/preserved?version=#{mock_version}"

        expect(response.headers["Last-Modified"]).to be <= Time.now.utc.rfc2822
        expect(response.headers["Last-Modified"]).to be >= last_modified_lower_bound
        expect(response.headers["Content-Type"]).to eq("application/octet-stream")
        expect(response.headers["Content-Disposition"]).to eq "attachment; filename=\"preserved+file.txt\"; filename*=UTF-8''preserved+file.txt"
        expect(response.code).to eq("200")
        expect(Preservation::Client.objects).to have_received(:content)
          .with(druid:, filepath: mock_file_name, version: mock_version, on_data: Proc)
      end

      context "when file not found in preservation" do
        let(:errmsg) { "it is fooched." }

        before do
          allow(Preservation::Client.objects).to receive(:content)
            .and_raise(Preservation::Client::NotFoundError, errmsg)
        end

        it "returns 404 with error information" do
          get "/items/#{druid}/files/not_there.txt/preserved?version=#{mock_version}"

          expect(response.headers["Content-Type"]).to eq("application/octet-stream")
          expect(response.headers["Last-Modified"]).to be_nil
          expect(response.headers["Content-Disposition"]).to be_nil
          expect(response.code).to eq("404")
          expect(response.body).to eq("Preserved file not found: #{errmsg}")
        end
      end

      context "when preservation-client raises an error other than NotFoundError" do
        let(:errmsg) { "something is busted" }

        before do
          allow(Preservation::Client.objects).to receive(:content)
            .and_raise(Preservation::Client::UnexpectedResponseError, errmsg)
          allow(Rails.logger).to receive(:error)
          allow(Honeybadger).to receive(:notify)
        end

        it "renders an HTTP 500 message" do
          get "/items/#{druid}/files/not_there.txt/preserved?version=#{mock_version}"

          expect(Rails.logger).to have_received(:error)
            .with(/Preservation client error getting content of not_there.txt for #{druid} \(version #{mock_version}\): #{errmsg}/).once
          expect(Honeybadger).to have_received(:notify).with(
            /Preservation client error getting content of not_there.txt for #{druid} \(version #{mock_version}\): #{errmsg}/
          ).once
          expect(response).to have_http_status(:internal_server_error)
          expect(response.body).to eq "Preservation client error getting content of not_there.txt for #{druid} (version #{mock_version}): #{errmsg}"
        end
      end
    end
  end

  describe "show locations of files" do
    let(:workflow_client) { instance_double(Dor::Workflow::Client, lifecycle: true) }

    before do
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    end

    it "requires an id parameter" do
      expect { get "/items/#{druid}/files" }.to raise_error(ArgumentError)
    end

    context "when the files are in preservation" do
      before do
        allow(Preservation::Client.objects).to receive(:current_version).with(druid).and_return("7")
      end

      it "is successful" do
        get "/items/#{druid}/files?id=M1090_S15_B01_F07_0106.jp2"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include "/items/druid:bc123df4567/files/M1090_S15_B01_F07_0106.jp2/preserved?version=7"
      end
    end

    context "when files are not in preservation" do
      before do
        allow(Preservation::Client.objects).to receive(:current_version).with(druid).and_raise(Preservation::Client::NotFoundError)
      end

      it "renders an HTTP 422 message" do
        get "/items/#{druid}/files?id=bar.tif"

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to eq "Preservation has not yet received #{druid}"
      end
    end

    context "when preservation-client raises an error other than NotFoundError" do
      before do
        allow(Preservation::Client.objects).to receive(:current_version).with(druid).and_raise(Preservation::Client::UnexpectedResponseError, "something is busted")
        allow(Rails.logger).to receive(:error)
        allow(Honeybadger).to receive(:notify)
      end

      it "renders an HTTP 500 message" do
        get "/items/#{druid}/files?id=bar.tif"

        expect(Rails.logger).to have_received(:error).with(/something is busted/).once
        expect(Honeybadger).to have_received(:notify).with(/something is busted/).once
        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to eq "Preservation client error getting current version of #{druid}: something is busted"
      end
    end
  end
end
