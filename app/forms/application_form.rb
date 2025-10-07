# frozen_string_literal: true

class ApplicationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  def self.model_name
    # Remove the "Form" suffix from the class name.
    # This allows Rails magic such as route paths.
    ActiveModel::Name.new(self, nil, to_s.delete_suffix('Form'))
  end
end
