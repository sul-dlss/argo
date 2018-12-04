# frozen_string_literal: true

class NullUser
  # rubocop:disable Naming/PredicateName
  def is_admin?
    false
  end

  def is_manager?
    false
  end

  def is_viewer?
    false
  end
  # rubocop:enable Naming/PredicateName

  def permitted_apos
    []
  end
end
