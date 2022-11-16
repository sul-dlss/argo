# frozen_string_literal: true

# Groups descriptions based on like data (e.g., form type values, note label
# values) for easier comprehension by users
class DescriptionsGrouper
  def self.group(descriptions:)
    new(descriptions:).group
  end

  def initialize(descriptions:)
    @descriptions = descriptions
  end

  def group
    descriptions.then { |descs| FormsGrouper.group(descriptions: descs) }
      .then { |descs| NotesGrouper.group(descriptions: descs) }
  end

  private

  attr_reader :descriptions
end
