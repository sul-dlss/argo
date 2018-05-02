# this is used when we don't have the Devise helper available
module SigninHelper
  def sign_in(user)
    allow(controller).to receive(:current_user).and_return(user)
  end
end
