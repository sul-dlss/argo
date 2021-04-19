class RegisterAgreement
  def self.register(model:, uploaded_file:)
    new(model: model, uploaded_file: uploaded_file).register
  end

  def initialize(model:, uploaded_file:)
    @model = model
    @uploaded_file = uploaded_file
  end

  def register
    md5 = `md5 -q #{uploaded_file.tempfile.path}`.chomp
    filename = uploaded_file.original_filename
    file_metadata = SdrClient::Deposit::Files::DirectUploadRequest.new(
      checksum: md5,
      byte_size: uploaded_file.size,
      content_type: uploaded_file.content_type,
      filename: filename
    )
    SdrClient::Login.run(url: Settings.sdr_api.url, login_service: TokensController::LoginFromSettings)

    connection = SdrClient::Connection.new(url: Settings.sdr_api.url, token: SdrClient::Credentials.read)


    upload_responses = SdrClient::Deposit::UploadFiles.upload(file_metadata: { filename => file_metadata },
                                           logger: Rails.logger,
                                           connection: connection)

    new_request_dro = SdrClient::Deposit::UpdateDroWithFileIdentifiers.update(request_dro: model,
                                                                              upload_responses: upload_responses)
    job_id = SdrClient::Deposit::CreateResource.run(accession: false,
                                                     metadata: new_request_dro,
                                                     logger: Rails.logger,
                                                     connection: connection)

    poll_for_job_complete(job_id: job_id)
  end

  private

  attr_reader :uploaded_file, :model

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
