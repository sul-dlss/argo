# frozen_string_literal: true

class NullUser
  def admin?
    false
  end

  def manager?
    false
  end

  def viewer?
    false
  end

  def sdr_api_authorized?
    false
  end

  def permitted_apos
    []
  end
end
