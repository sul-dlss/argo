# frozen_string_literal: true

desc 'Manage all the things'
task manage: :environment do
  puts Tcramer.manage
end
