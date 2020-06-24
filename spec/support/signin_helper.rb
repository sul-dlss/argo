# frozen_string_literal: true

module SigninHelper
  def mock_user(attributes = {})
    double(:webauth_user, {
      login: 'sunetid',
      logged_in?: true,
      privgroup: [],
      groups: [],
      admin?: false,
      webauth_admin?: attributes[:admin?],
      manager?: false,
      viewer?: false,
      roles: [],
      permitted_apos: [],
      permitted_collections: []
    }.merge(attributes))
  end
end
