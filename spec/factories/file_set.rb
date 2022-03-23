# frozen_string_literal: true

FactoryBot.define do
  factory :file_set do
    initialize_with do
      new(
        Cocina::Models::FileSet.new(
          type: type,
          label: label,
          version: version,
          externalIdentifier: 'https://cocina.sul.stanford.edu/file/b7cdfa7a-6e1f-484b-bbb0-f9a46c40dbb4',
          structural: {
            contains: file_sets
          }
        )
      )
    end

    version { 1 }
    label { 'test file set' }
    type { Cocina::Models::ObjectType.file_set }
    file_sets { [] }
  end
end
