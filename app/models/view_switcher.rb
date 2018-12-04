# frozen_string_literal: true

##
# Holds structure needed to switch views between controllers
class ViewSwitcher
  attr_reader :name, :path
  ##
  # @param [Symbol] name name of "view" used for switching between controllers
  # @param [Symbol] path named route path helper method
  def initialize(name, path)
    @name = name
    @path = path
  end
end
