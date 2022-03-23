# frozen_string_literal: true

# Represents a set of changes to a collection
class CollectionChangeSet < ApplicationChangeSet
  property :admin_policy_id
  property :catkeys
  property :copyright
  property :license
  property :use_statement
  property :source_id
  property :view_access

  def self.model_name
    ::ActiveModel::Name.new(nil, nil, 'Collection')
  end
end
