# frozen_string_literal: true

# Represents a set of changes to a collection
class CollectionChangeSet < Reform::Form
  property :copyright_statement, virtual: true
  property :license, virtual: true
  property :use_statement, virtual: true

  def save_model
    CollectionChangeSetPersister.update(model, self)
  end
end
