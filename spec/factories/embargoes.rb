# frozen_string_literal: true

FactoryBot.define do
  factory :embargo do
    initialize_with do
      new(
        Cocina::Models::Embargo.new(
          'releaseDate' => '2040-05-05',
          'view' => 'stanford',
          'download' => 'stanford'
        )
      )
    end
  end
end
