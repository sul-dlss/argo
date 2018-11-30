module ProfileHelper
  include Blacklight::CatalogHelperBehavior
  ##
  # Kind of a hacky override, but better than overriding additional partials
  # Don't show pagination for ProfileController requests
  def show_pagination?(*)
    return false if params['controller'] == 'profile'

    super
  end
end
