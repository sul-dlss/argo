# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence :sunetid do |n|
      "person#{n}"
    end
  end
end
