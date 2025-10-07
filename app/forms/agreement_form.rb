# frozen_string_literal: true

class AgreementForm < ApplicationForm
  attribute :title, :string
  validates :title, presence: true

  attribute :source_id, :string
  validates :source_id, format: { with: Regexp.new(Settings.source_id_regex),
                                  message: 'must have a single colon in the middle' },
                        presence: true

  attribute :agreement_file1
  validates :agreement_file1, presence: true

  attribute :agreement_file2

  # druid is set when the form is saved.
  attribute :id

  def save
    self.id = RegisterAgreement.register(model:, uploaded_files: agreement_files)
  end

  private

  def model
    Cocina::Models.build_request({
                                   'type' => Cocina::Models::ObjectType.agreement,
                                   'label' => title,
                                   'version' => 1,
                                   'access' => { 'view' => 'dark' },
                                   'description' => { 'title' => [{ 'value' => title }] },
                                   'administrative' => { 'hasAdminPolicy' => ApoConcern::UBER_APO_ID },
                                   'identification' => { 'sourceId' => source_id },
                                   'structural' => {
                                     'contains' => [
                                       {
                                         'type' => Cocina::Models::FileSetType.file,
                                         'label' => 'Agreement',
                                         'version' => 1,
                                         'structural' => {
                                           'contains' => agreement_files.map { |file| file_structure(file).to_h }
                                         }
                                       }
                                     ]
                                   }
                                 })
  end

  def agreement_files
    [agreement_file1, agreement_file2].compact
  end

  def file_structure(file)
    path = file_path(file)
    FileGenerator.generate(uploaded_file: file,
                           label: 'Agreement file',
                           md5: md5(path),
                           sha1: sha1(path))
  end

  def md5(path)
    SdrClient::Deposit::FileMetadataBuilderOperations::MD5.for(filepath: path)
  end

  def sha1(path)
    SdrClient::Deposit::FileMetadataBuilderOperations::SHA1.for(filepath: path)
  end

  def file_path(file)
    file.tempfile.path
  end
end
