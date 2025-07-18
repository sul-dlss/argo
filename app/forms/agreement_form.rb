# frozen_string_literal: true

class AgreementForm < Reform::Form
  property :title, virtual: true
  property :source_id, virtual: true
  property :agreement_file1, virtual: true
  property :agreement_file2, virtual: true

  validates :title, presence: true
  validates :source_id, format: { with: Regexp.new(Settings.source_id_regex),
                                  message: 'must have a single colon in the middle' },
                        presence: true
  validates :agreement_file1, presence: true

  def persisted?
    false
  end

  def to_key
    []
  end

  def sync!(_props)
    @model = new_resource(title:, source_id:)
  end

  def save_model
    @model = Result.new(RegisterAgreement.register(model:, uploaded_files: agreement_files))
  end

  Result = Struct.new(:externalIdentifier) # rubocop:disable Naming/MethodName

  def new_resource(title:, source_id:)
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
