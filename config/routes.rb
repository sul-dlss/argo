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
  match '/report/bulk', :to => "report#bulk", :as => "report_bulk"
  match 'report/pids', :to => "report#pids", :as => 'report_pids'
  match '/report/workflow_grid', :to => "report#workflow_grid", :as => "report_workflow_grid"
  
  root :to => "catalog#index"

  match 'login',          :to => 'auth',       :as => 'new_user_session'
  match 'logout',         :to => 'auth',       :as => 'destroy_user_session'
  match 'profile',        :to => 'auth',       :as => 'edit_user_registration'
  
  namespace :report do
    get '/workflow_grid'
  end
  
  resources :apo do
    get 'apo_ui', :on => :member, :action => :apo_ui, :as => 'apo_ui'
    get 'delete_role', :on => :member
    post 'add_collection', :on => :member
    get 'delete_collection', :on => :member
    post 'update_title', :on => :member
    post 'update_creative_commons', :on => :member
    post 'update_use', :on => :member
    post 'update_copyright', :on => :member
    post 'update_default_object_rights', :on => :member
    post 'add_roleplayer', :on => :member
    post 'update_desc_metadata', :on => :member
    get :register, :on => :collection
    post :register, :on => :collection
    post :update, :on => :member

  end
  resources :items do
    get :crop, :on => :member
    put :crop, :on => :member, :action => :save_crop
    get :register, :on => :collection
    get  '/workflows/:wf_name', :on => :member, :action => :workflow_view,   :as => 'workflow_view'
    post '/workflows/:wf_name', :on => :member, :action => :workflow_update, :as => 'workflow_update'
    get '/workflow/history', :on => :member, :action => :workflow_history_view, :as => 'workflow_history_view'
    post '/embargo', :on => :member, :action => :embargo_update, :as => 'embargo_update'
    post '/datastream', :on => :member, :action => :datastream_update, :as => 'datastream_update'
    get '/file', :on => :member, :action => :get_file, :as => 'get_file'
    get '/file_list', :on => :member, :action => :file, :as => 'file'
    post '/file', :on => :member, :action => :replace_file, :as => 'replace_file'
    get '/resource', :on => :member, :action=>:resource, :as =>'resource'
    delete '/file', :on => :member, :action => :delete_file, :as => 'delete_file'
    post '/add_file', :on => :member, :action => :add_file, :as => 'add_file'
    post '/file/attributes', :on => :member, :action => :update_attributes, :as => 'update_attributes'
    get 'close_version_ui', :on => :member, :action => :close_version_ui, :as => 'close_version_ui'
    post 'close_version_ui', :on => :member, :action => :close_version_ui, :as => 'close_version_ui'
    get 'open_version_ui', :on => :member, :action => :open_version_ui, :as => 'open_version_ui'
    post 'open_version_ui', :on => :member, :action => :open_version_ui, :as => 'open_version_ui'
    get '/version/open', :action=>:open_version, :as => 'open_version'
    get '/source_id_ui', :on => :member, :action => :source_id_ui, :as => 'source_id_ui'
    get '/tags_ui', :on => :member, :action => :tags_ui, :as => 'tags_ui'
    get '/tags', :on => :member, :action => :tags, :as => 'tags'
    post '/tags', :on => :member, :action => :tags, :as => 'tags'
    get '/collection_ui', :on => :member, :action => :collection_ui, :as => 'collection_ui' 
    get '/collection/delete', :on => :member, :action => :remove_collection, :as => 'remove_collection'
    post '/collection/add', :on => :member, :action => :add_collection, :as => 'add_collection'
    get '/purge', :on => :member, :action => :purge_object
    post '/set_content_type', :on => :member, :action => :set_content_type
    get '/content_type', :on => :member, :action => :content_type
    get '/rights', :on => :member, :action => :rights
    post '/prepare', :on => :member, :action => :prepare
    post '/set_rights', :on => :member, :action => :set_rights
  end
  
  namespace :items do
    post '/version/close', :action=>:close_version, :as => 'close_version'
    post '/version/open', :action=>:open_version, :as => 'open_version'
    post '/source_id', :action => :source_id, :as => 'source_id'
  end
  
  namespace :status do
    get "log"
    get "memcached"
  end
  
  namespace :registration do
    get "/", :action => :form
    get "/tracksheet"
    get "/form_list"
    get "/collection_list"
    get "/workflow_list"
    get "/rights_list", :action => :rights_list, :as => 'rights_list'
    get "/suggest_project", :action => 'autocomplete', :field => 'project_tag_facet'
  end

  namespace :auth do
    get '/login'
    get '/logout'
    get '/profile'
    get '/groups'
    post '/set_groups', :action => :set_groups, :as => 'set_groups'
    get '/remove_groups'
  end

	namespace :dor do
    get '/configuration'
    get '/label'
    get '/query_by_id'
    match 'republish/:pid', :action => :republish
    match 'archive/:pid', :action => :archive_workflows
    match 'reindex/:pid', :action => :reindex, :as => 'reindex'
    match 'delete_from_index/:pid', :action => :delete_from_index
    get '/index_exceptions'
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
