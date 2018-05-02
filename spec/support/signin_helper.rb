module SigninHelper
  def mock_user(attributes = {})
    double(:webauth_user, {
      login: 'sunetid',
      logged_in?: true,
      privgroup: [],
      groups: [],
      is_admin?: false,
      is_webauth_admin?: attributes[:is_admin?],
      is_manager?: false,
      is_viewer?: false,
      roles: [],
      permitted_apos: [],
      permitted_collections: []
    }.merge(attributes))
  end
end
