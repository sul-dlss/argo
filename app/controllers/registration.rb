RubyDorServices.controllers :registration do

  get :single do
    render 'registration/single'
  end
  
  get :bulk do
    render 'registration/bulk'
  end

end