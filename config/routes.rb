Argo::Application.routes.draw do

  Blacklight::Marc.add_routes(self)
  Blacklight.add_routes(self, :except => [:catalog])
  # Catalog stuff.
  match 'view/opensearch', :to => 'catalog#opensearch', :via => [:get, :post]
  match 'view/citation',   :to => 'catalog#citation',   :via => [:get, :post]
  match 'view/email',      :to => 'catalog#email',      :via => [:get, :post]
  match 'view/sms',        :to => 'catalog#sms',        :via => [:get, :post]
  match 'view/endnote',    :to => 'catalog#endnote',    :via => [:get, :post]
  match 'view/send_email_record', :to => 'catalog#send_email_record', :via => [:get, :post]
  match "view/facet/:id",  :to => 'catalog#facet', :via => [:get, :post]
  match 'view/unapi',      :to => "catalog#unapi", :via => [:get, :post], :as => 'unapi'
  resources :catalog, :path => '/view', :only => [:index, :show, :update]
  match 'view/:id/dc',                :to => "catalog#show_aspect",     :via => [:get, :post], :template => 'dc', :as => "dc_aspect_view_catalog"
  match 'view/:id/ds/:dsid',          :to => "catalog#show_aspect",     :via => [:get, :post], :template => 'ds', :as => 'ds_aspect_view_catalog'
  match 'view/:id/datastreams/:dsid', :to => "catalog#datastream_view", :via => [:get, :post], :as => "datastream_view_catalog"

  match 'catalog/:id/bulk_upload_form',   :to => 'catalog#bulk_upload_form',  :as => 'bulk_upload_form',   :via => [:get]
  match 'catalog/:id/upload',             :to => 'catalog#upload',            :as => 'upload',             :via => [:post]
  match 'catalog/:id/bulk_jobs_index',    :to => 'catalog#bulk_jobs_index',   :as => 'bulk_jobs_index',    :via => [:get]
  match 'catalog/:id/bulk_status_help',   :to => 'catalog#bulk_status_help',  :as => 'bulk_status_help',   :via => [:get]
  match 'catalog/:xml/bulk_jobs_xml',      :to => 'catalog#bulk_jobs_xml',     :as => 'bulk_jobs_xml',      :via => [:get]
  
  #TODO: looks like Blacklight::Marc.add_routes deals w/ librarian_view now?
  # match 'view/:id/librarian_view', :to => "catalog#librarian_view", :via => [:get, :post], :as => "librarian_view_catalog"
  match '/catalog', :via => [:get, :post], :to => redirect { |params,req| req.fullpath.sub(%r{^/catalog},'/view') }
  match '/catalog/*all', :via => [:get, :post], :to => redirect { |params,req| req.fullpath.sub(%r{^/catalog},'/view') }
  mount AboutPage::Engine => '/about(.:format)'
  match '/report', :to => "report#index", :via => [:get, :post], :as => "report"
  match '/report/data', :to => "report#data", :via => [:get, :post], :as => "report_data"
  match '/report/download', :to => "report#download", :via => [:get, :post], :as => "report_download"
  match '/report/bulk', :to => "report#bulk", :via => [:get, :post], :as => "report_bulk"
  match 'report/pids', :to => "report#pids", :via => [:get, :post], :as => 'report_pids'
  match '/report/workflow_grid', :to => "report#workflow_grid", :via => [:get, :post], :as => "report_workflow_grid"
  match 'report/reset', :to => "report#reset", :via => [:get, :post], :as => 'report_reset'
  match 'discovery', :to => 'discovery#index', :via => [:get, :post], :as => 'discovery'
  match '/discovery/data', :to => "discovery#data", :via => [:get, :post], :as => "discovery_data"
  match 'discovery/download', :to => 'discovery#download', :via => [:get, :post], :as => 'discovery_download'
  match '/apo/is_valid_role_list', :to => 'apo#is_valid_role_list_endpoint', :via => [:get, :post], :as => 'is_valid_role_list'

  root :to => "catalog#index"

  match 'login',   :controller => 'auth', :as => 'new_user_session',       :via => [:get, :post]
  match 'logout',  :controller => 'auth', :as => 'destroy_user_session',   :via => [:get, :post]
  match 'profile', :controller => 'auth', :as => 'edit_user_registration', :via => [:get, :post]

  namespace :report do
    get '/workflow_grid', :action => :workflow_grid
  end

  resources :robot do
  end

  resources :apo do
    get 'apo_ui', :on => :member, :action => :apo_ui, :as => 'apo_ui'
    get 'delete_role', :on => :member
    post 'add_collection', :on => :member
    get  'delete_collection', :on => :member
    post 'update_title', :on => :member
    post 'update_creative_commons', :on => :member
    post 'update_use', :on => :member
    post 'update_copyright', :on => :member
    post 'update_default_object_rights', :on => :member
    post 'add_roleplayer', :on => :member
    post 'update_desc_metadata', :on => :member
    get  :register, :on => :collection
    post :register, :on => :collection
    post :update, :on => :member
    get  :register_collection, :on => :member
    post :register_collection, :on => :member
    get :spreadsheet_template, :on => :collection
  end

  resources :items do
    get :crop, :on => :member
    put :crop, :on => :member, :action => :save_crop
    get :register, :on => :collection
    get 'purl_preview', :on => :member, :action => :purl_preview, :as => 'purl_preview'
    get '/discoverable', :on => :member, :action => :discoverable, :as => 'discoverable'
    get '/refresh_metadata', :on => :member, :action => :refresh_metadata, :as => 'refresh_metadata'
    get '/schema_validate', :on => :member, :action => :schema_validation, :as => 'schema_validation'
    get '/remediate_mods', :on => :member, :action => :remediate_mods, :as => 'remediate_mods'
    get '/mods', :on => :member, :action => :mods, :as => 'mods'
    post '/mods', :on => :member, :action => :update_mods, :as => 'update_mods'
    get '/remove_duplicate_encoding', :on => :member, :action => :remove_duplicate_encoding, :as => 'remove_duplicate_encoding'
    get '/detect_duplicate_encoding', :on => :member, :action => :detect_duplicate_encoding, :as => 'detect_duplicate_encoding'
    get '/create_minimal_mods', :on => :member, :action => :create_minimal_mods, :as => 'create_minimal_mods'
    get  '/workflows/:wf_name', :on => :member, :action => :workflow_view,   :as => 'workflow_view'
    post '/workflows/:wf_name', :on => :member, :action => :workflow_update, :as => 'workflow_update'
    get '/workflow/history', :on => :member, :action => :workflow_history_view, :as => 'workflow_history_view'
    post '/embargo', :on => :member, :action => :embargo_update, :as => 'embargo_update'
    get '/embargo_form', :on => :member, :action => :embargo_form, :as => 'embargo_form'
    post '/datastream', :on => :member, :action => :datastream_update, :as => 'datastream_update'
    get '/file', :on => :member, :action => :get_file, :as => 'get_file'
    get '/file_list', :on => :member, :action => :file, :as => 'file'
    post '/file', :on => :member, :action => :replace_file, :as => 'replace_file'
    get '/resource', :on => :member, :action=>:resource, :as =>'resource'
    delete '/file', :on => :member, :action => :delete_file, :as => 'delete_file'
    post '/add_file', :on => :member, :action => :add_file, :as => 'add_file'
    post '/file/attributes', :on => :member, :action => :update_attributes, :as => 'update_attributes'
    # get 'close_version_ui', :on => :member, :action => :close_version_ui, :as => 'close_version_ui'
    # post 'close_version_ui', :on => :member, :action => :close_version_ui, :as => 'close_version_ui'
    match 'close_version_ui', :on => :member, :action => :close_version_ui, :as => 'close_version_ui', :via => [:get, :post]
    # get 'open_version_ui', :on => :member, :action => :open_version_ui, :as => 'open_version_ui'
    # post 'open_version_ui', :on => :member, :action => :open_version_ui, :as => 'open_version_ui'
    match 'open_version_ui', :on => :member, :action => :open_version_ui, :as => 'open_version_ui', :via => [:get, :post]
    get '/version/open', :action=>:open_version, :as => 'open_version'
    get '/source_id_ui', :on => :member, :action => :source_id_ui, :as => 'source_id_ui'
    get '/tags_ui', :on => :member, :action => :tags_ui, :as => 'tags_ui'
    # get '/tags', :on => :member, :action => :tags, :as => 'tags'
    # post '/tags', :on => :member, :action => :tags, :as => 'tags'
    match '/tags', :on => :member, :action => :tags, :as => 'tags', :via => [:get, :post]
    # get '/tags_bulk', :on => :member, :action => :tags_bulk, :as => 'tags_bulk'
    # post '/tags_bulk', :on => :member, :action => :tags_bulk, :as => 'tags_bulk'
    match '/tags_bulk', :on => :member, :action => :tags_bulk, :as => 'tags_bulk', :via => [:get, :post]
    get '/collection_ui', :on => :member, :action => :collection_ui, :as => 'collection_ui'
    get '/collection/delete', :on => :member, :action => :remove_collection, :as => 'remove_collection'
    post '/collection/add', :on => :member, :action => :add_collection, :as => 'add_collection'
    post '/collection/set', :on => :member, :action => :set_collection, :as => 'set_collection'
    get '/purge', :on => :member, :action => :purge_object
    post '/set_content_type', :on => :member, :action => :set_content_type
    get '/content_type', :on => :member, :action => :content_type
    get '/rights', :on => :member, :action => :rights
    post '/prepare', :on => :member, :action => :prepare
    post '/set_rights', :on => :member, :action => :set_rights
    get '/preserved_file', :on => :member, :action => :get_preserved_file
    post :release_hold, :on => :member
    match :add_workflow, :on => :member, :action => :add_workflow, :as => 'add_workflow', :via => [:get, :post]
    get :apply_apo_defaults, :on => :member
    get :fix_missing_provenance, :on => :member
    match :update_resource, :on => :member, :action => :update_resource, :as => 'update_resource', :via => [:get, :post]
  end

  namespace :items do
    post '/version/close', :action=>:close_version, :as => 'close_version'
    post '/version/open', :action=>:open_version, :as => 'open_version'
    post '/source_id', :action => :source_id, :as => 'source_id'
    post '/add_collection', :action => :add_collection, :as => 'add_collection'
    post '/set_collection', :action => :set_collection, :as => 'set_collection'
  end

  namespace :status do
    get "log"
    get "memcached"
  end

  namespace :registration do
    get "/", :action => :form
    get "tracksheet"
    get "form_list"
    get "collection_list"
    get "workflow_list"
    get "/rights_list", :action => :rights_list, :as => 'rights_list'
    get "/suggest_project", :action => 'autocomplete', :field => 'project_tag_ssim'
  end

  namespace :auth do
    get 'login'
    get 'logout'
    get 'profile'
    get 'groups'
    post '/remember_impersonated_groups', :action => :remember_impersonated_groups, :as => 'remember_impersonated_groups'
    get 'forget_impersonated_groups'
  end

  namespace :dor do
    get 'configuration'
    get 'label'
    get 'query_by_id'
    match 'republish/:pid', :action => :republish, :via => [:get, :post]
    match 'archive/:pid', :action => :archive_workflows, :via => [:get, :post]
    match 'reindex/:pid', :action => :reindex, :as => 'reindex', :via => [:get, :post]
    match 'delete_from_index/:pid', :action => :delete_from_index, :via => [:get, :post]
    get 'index_exceptions'
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
