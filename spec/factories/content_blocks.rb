# frozen_string_literal: true

FactoryBot.define do
  factory :content_block do
    value { 'MyText' }
    start_at { '2020-05-14 12:18:19' }
    end_at { '2020-05-14 12:18:19' }
    ordinal { 1 }
  end
end
