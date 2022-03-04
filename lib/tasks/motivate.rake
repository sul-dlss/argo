# frozen_string_literal: true

desc 'Motivate your employees'
task motivate: :environment do
  puts Tcramer.motivate
end
