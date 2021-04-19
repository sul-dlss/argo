# frozen_string_literal: true

class AgreementForm < Reform::Form
  property :title, virtual: true
  property :source_id, virtual: true
  property :agreement_file, virtual: true

  validates :source_id, format: { with: /\A\w+:\w+\z/,
                                  message: 'must have a colon' }

  def persisted?
    false
  end

  def to_key
    []
  end

  def sync!(_props)
    @model = new_resource(title: title, source_id: source_id)
  end

  def save_model
    @model = Dor::Services::Client.objects.register(params: model)
  end

  def new_resource(title:, source_id:)
    Cocina::Models.build_request(
      'type' => Cocina::Models::Vocab.agreement,
      'label' => title,
      'version' => 1,
      'access' => { 'access' => 'dark' },
      'description' => { 'title' => [{ 'value' => title }] },
      'administrative' => { 'hasAdminPolicy' => ApoConcern::UBER_APO_ID },
      'identification' => { 'sourceId' => source_id },
      'structural' => {}
    )
  end
end
