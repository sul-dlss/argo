# this is used when we don't have the Devise helper available
module SigninHelper
  def sign_in(user)
    allow(controller).to receive(:current_user).and_return(user)
  end

  def log_in_as_mock_user(attributes = {})
    sign_in(mock_user(attributes))
  end

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
