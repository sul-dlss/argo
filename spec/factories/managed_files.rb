# frozen_string_literal: true

FactoryBot.define do
  factory :managed_file do
    initialize_with do
      new(
        Cocina::Models::File.new(
          type: type,
          label: label,
          version: version,
          filename: '0220_MLK_Kids_Gadson_459-25.tif',
          externalIdentifier: 'https://cocina.sul.stanford.edu/file/b7cdfa7a-6e1f-484b-bbb0-f9a46c40dbb4',
          hasMimeType: 'image/tiff',
          size: 99,
          access: {
            view: 'world',
            download: 'stanford'
          },
          administrative: {
            sdrPreserve: true,
            publish: true,
            shelve: true
          }
        )
      )
    end

    version { 1 }
    label { 'test file' }
    type { Cocina::Models::ObjectType.file }

    trait :transcription do
      use { 'transcription' }
    end
  end
end
