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
    return 'You are viewing the latest version.' if @presenter.head_user_version_view?

    'You are viewing an older version.' if @presenter.user_version_view?
  end
end
