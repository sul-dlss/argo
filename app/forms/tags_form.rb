# frozen_string_literal: true

class TagsForm < Reform::Form
  collection :tags, populator: lambda { |collection:, index:, fragment:, **|
                                 if (item = collection.find { |tag| fragment[:id].present? && tag.id == fragment[:id] })
                                   item
                                 else
                                   collection.insert(index, TagsController::Tag.new)
                                 end
                               } do
    property :id # really just the previous value
    property :name
    property :_destroy, virtual: true
    validates :name, format: { with: /.+( : .+)+/, message: "must include the pattern:

[term] : [term]

It's legal to have more than one colon in a hierarchy, but at least one colon is required." }
  end

  def save
    add_tags
    remove_tags
    update_tags
  end

  private

  def add_tags
    return if tags_to_add.blank?

    tags = tags_to_add.map(&:name).compact_blank
    tags_client.create(tags:) if tags.any?
  end

  def remove_tags
    tags_to_remove.map(&:id).each do |tag_to_delete|
      raise 'failed to delete' unless tags_client.destroy(tag: tag_to_delete)
    end
  end

  def update_tags
    tags_to_update.each do |tag|
      tags_client.update(current: tag.id, new: tag.name)
    end
  end

  def tags_to_add
    @tags_to_add ||= tags.select { |tag| tag._destroy != '1' && tag.id.blank? }
  end

  def tags_to_update
    tags.select { |tag| tag._destroy != '1' && tag.id.present? }
  end

  def tags_to_remove
    tags.select { |tag| tag._destroy == '1' }
  end

  def tags_client
    Dor::Services::Client.object(model.to_param).administrative_tags
  end
end
