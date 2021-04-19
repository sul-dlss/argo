# frozen_string_literal: true

class RegisterAgreement
  def self.register(model:, uploaded_files:)
    new(model: model, uploaded_files: uploaded_files).register
  end

  def initialize(model:, uploaded_files:)
    @model = model
    @uploaded_files = uploaded_files
  end

  def metadata_for(file)
    md5 = Digest::MD5.file(file.tempfile.path).base64digest
    filename = file.original_filename
    SdrClient::Deposit::Files::DirectUploadRequest.new(
      checksum: md5,
      byte_size: file.size,
      content_type: file.content_type,
      filename: filename
    )
  end

  def register
    file_metadata = uploaded_files.compact.each_with_object({}) do |file, o|
      o[file.tempfile.path] = metadata_for(file)
    end
    SdrClient::Login.run(url: Settings.sdr_api.url, login_service: TokensController::LoginFromSettings)

    connection = SdrClient::Connection.new(url: Settings.sdr_api.url, token: SdrClient::Credentials.read)
    upload_responses = SdrClient::Deposit::UploadFiles.upload(file_metadata: file_metadata,
                                                              logger: Rails.logger,
                                                              connection: connection)

    new_request_dro = SdrClient::Deposit::UpdateDroWithFileIdentifiers.update(request_dro: model,
                                                                              upload_responses: upload_responses)
    job_id = SdrClient::Deposit::CreateResource.run(accession: true,
                                                    metadata: new_request_dro,
                                                    logger: Rails.logger,
                                                    connection: connection)

    poll_for_job_complete(job_id: job_id)
  end

  private

  attr_reader :uploaded_files, :model

  def poll_for_job_complete(job_id:)
    result = nil
    1.upto(5) do |_n|
      result = SdrClient::BackgroundJobResults.show(url: Settings.sdr_api.url, job_id: job_id)
      break unless %w[pending processing].include? result['status']

      sleep 5
    end
    if result['status'] == 'complete'
      result.dig('output', 'druid')
    else
      warn "Job #{job_id} did not complete\n#{result.inspect}"
    end
  end
end
