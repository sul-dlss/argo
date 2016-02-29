class NullUser
  # rubocop:disable Style/PredicateName
  def is_admin?
    false
  end

  def is_manager?
    false
  end

  def is_viewer?
    false
  end
  # rubocop:enable Style/PredicateName

  def permitted_apos
    []
  end
end
