# typed: true
# frozen_string_literal: true

# This generates a File for a work
class FileGenerator
  def self.generate(uploaded_file:, label:)
    new(uploaded_file: uploaded_file, label: label).generate
  end

  def initialize(uploaded_file:, label:)
    @uploaded_file = uploaded_file
    @label = label
  end

  attr_reader :uploaded_file, :label

  def generate
    Cocina::Models::RequestFile.new(request_file_attributes)
  end

  def request_file_attributes
    {
      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
      version: 1,
      label: label,
      filename: uploaded_file.original_filename,
      access: access,
      administrative: administrative,
      hasMimeType: uploaded_file.content_type,
      hasMessageDigests: message_digests,
      size: uploaded_file.size
    }
  end

  def file_attributes
    request_file_attributes.merge(externalIdentifier: external_identifier)
  end

  def filename
    blob.filename.to_s
  end

  def external_identifier
    "#{work_version.work.druid}/#{filename}" if work_version.work.druid
  end

  def administrative
    {
      publish: false,
      sdrPreserve: true,
      shelve: false
    }
  end

  def message_digests
    [
      { type: 'md5', digest: `md5 -q #{uploaded_file.tempfile.path}`.chomp },
      { type: 'sha1', digest: `shasum #{uploaded_file.tempfile.path} | awk '{ print $1 }'`.chomp}
    ]
  end

  def blob
    @blob ||= uploaded_file.file&.attachment&.blob
  end

  def access
    { access: 'dark', download: 'none' }
  end

  def file_path(key)
    ActiveStorage::Blob.service.path_for(key)
  end

  def base64_to_hexdigest(base64)
    Base64.decode64(base64).unpack1('H*')
  end
end
