# frozen_string_literal: true

class DocumentTitleComponent < Blacklight::DocumentTitleComponent
  def object_type_label
    return 'apo' if @document.admin_policy?
    return 'virtual object' if @document.virtual_object?

    @document.object_type
  end

  def object_type_class
    object_type_label.tr(' ', '-')
  end

  def version_banner
    if head_user_version_view? || current_version_view?
      'You are viewing the latest version.'
    elsif invalid_cocina?
      "You are viewing an older #{version_type} version that is no longer valid. You can view the JSON below."
    elsif version_or_user_version_view?
      "You are viewing an older #{version_type} version."
    end
  end

  def show_latest_link?
    return previous_user_version_view? if @presenter.user_version_view?

    !current_version_view?
  end

  def version_type
    return 'public' if @presenter.user_version_view?

    'system'
  end

  delegate :version_or_user_version_view?, :head_user_version_view?, :previous_user_version_view?, :current_version_view?,
           :invalid_cocina?, to: :@presenter
end
