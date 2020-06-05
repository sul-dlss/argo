# frozen_string_literal: true

class ContentBlock < ApplicationRecord
  ORDINAL_STRING = { 1 => 'Primary', 2 => 'Secondary' }.freeze
  scope :expired, -> { where('end_at < ?', current_time) }
  scope :unexpired, -> { where('end_at >= ?', current_time) }
  scope :active, -> { where('start_at < ? AND end_at >= ?', current_time, current_time) }
  scope :primary, -> { where(ordinal: 1) }
  scope :secondary, -> { where(ordinal: 2) }

  validates :ordinal, presence: true, inclusion: { in: [1, 2] }

  def self.current_time
    Time.now.in_time_zone('America/Los_Angeles')
  end

  def ordinal_string
    ORDINAL_STRING.fetch(ordinal)
  end

  def pacific_start
    start_at.in_time_zone('America/Los_Angeles')
  end

  def pacific_end
    end_at.in_time_zone('America/Los_Angeles')
  end
end
