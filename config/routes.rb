Argo::Application.routes.draw do

  Blacklight.add_routes(self, :except => [:catalog])
  # Catalog stuff.
  match 'view/opensearch', :to => 'catalog#opensearch', :as => "opensearch_catalog"
  match 'view/citation', :to => 'catalog#citation', :as => "citation_catalog"
  match 'view/email', :to => 'catalog#email', :as => "email_catalog"
  match 'view/sms', :to => 'catalog#sms', :as => "sms_catalog"
  match 'view/endnote', :to => 'catalog#endnote', :as => "endnote_catalog"
  match 'view/send_email_record', :to => 'catalog#send_email_record', :as => "send_email_record_catalog"
  match "view/facet/:id", :to => 'catalog#facet', :as => 'catalog_facet'
  match 'view/unapi', :to => "catalog#unapi", :as => 'unapi'
  resources :catalog, :path => '/view', :only => [:index, :show, :update]
  match 'view/:id/dc', :to => "catalog#show_aspect", :template => 'dc', :as => "dc_aspect_view_catalog"
  match 'view/:id/ds/:dsid', :to => "catalog#show_aspect", :template => 'ds', :as => 'ds_aspect_view_catalog'
  match 'view/:id/datastreams/:dsid', :to => "catalog#datastream_view", :as => "datastream_view_catalog"
  match 'view/:id/librarian_view', :to => "catalog#librarian_view", :as => "librarian_view_catalog"
  match '/catalog', :to => redirect { |params,req| req.fullpath.sub(%r{^/catalog},'/view') }
  match '/catalog/*all', :to => redirect { |params,req| req.fullpath.sub(%r{^/catalog},'/view') }
  mount AboutPage::Engine => '/about(.:format)'
  match '/report', :to => "report#index", :as => "report"
  match '/report/data', :to => "report#data", :as => "report_data"
  match '/report/download', :to => "report#download", :as => "report_download"
  match '/report/workflow_grid', :to => "report#workflow_grid", :as => "report_workflow_grid"

  root :to => "catalog#index"

  match 'login',          :to => 'auth',       :as => 'new_user_session'
  match 'logout',         :to => 'auth',       :as => 'destroy_user_session'
  match 'profile',        :to => 'auth',       :as => 'edit_user_registration'
  
  namespace :report do
    get '/workflow_grid'
  end
  
  resources :items do
    get :crop, :on => :member
    put :crop, :on => :member, :action => :save_crop
    get :register, :on => :collection
    get  '/workflows/:wf_name', :on => :member, :action => :workflow_view,   :as => 'workflow_view'
    post '/workflows/:wf_name', :on => :member, :action => :workflow_update, :as => 'workflow_update'
  end
  
  namespace :registration do
    get "/", :action => :form
    get "/tracksheet"
    get "/form_list"
    get "/workflow_list"
    get "/rights_list"
    get "/suggest_project", :action => 'autocomplete', :field => 'project_tag_facet'
  end

  namespace :auth do
    get '/login'
    get '/logout'
    get '/profile'
  end
  
  namespace :dor do
    get '/configuration'
    get '/label'
    get '/query_by_id'
    match 'reindex/:pid', :action => :reindex
    match 'delete_from_index/:pid', :action => :delete_from_index
    resources :objects 
  end
  
  namespace :legacy do
    resources :objects
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
