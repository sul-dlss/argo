# frozen_string_literal: true

# Represents a set of changes to an item.
class ItemChangeSet
  def initialize
    @changes = {}
    yield self
  end

  def catkey=(key)
    @changes[:catkey] = key
  end

  def catkey
    @changes[:catkey]
  end

  def catkey_changed?
    @changes.key?(:catkey)
  end

  def collection_ids=(ids)
    @changes[:collection_ids] = ids
  end

  def collection_ids
    @changes[:collection_ids]
  end

  def collection_ids_changed?
    @changes.key?(:collection_ids)
  end

  def source_id=(id)
    @changes[:source_id] = id
  end

  def source_id
    @changes[:source_id]
  end

  def source_id_changed?
    @changes.key?(:source_id)
  end

  def admin_policy_id=(id)
    @changes[:admin_policy_id] = id
  end

  def admin_policy_id
    @changes[:admin_policy_id]
  end

  def admin_policy_id_changed?
    @changes.key?(:admin_policy_id)
  end
end
