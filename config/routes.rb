Argo::Application.routes.draw do
  get '/is_it_working' => 'ok_computer/ok_computer#show', defaults: { check: 'default' }

  resources :bulk_actions, except: [:edit, :show, :update] do
    member do
      get :file
    end
  end

  mount Blacklight::Engine => '/'


  concern :searchable, Blacklight::Routes::Searchable.new
  concern :exportable, Blacklight::Routes::Exportable.new

  resource :profile, controller: 'profile', only: [:index] do
    concerns :searchable
  end

  resource :catalog, only: [:index], controller: 'catalog', path: '/catalog' do
    concerns :searchable
  end

  resources :solr_documents, only: [:show, :update], controller: 'catalog', path: '/view' do
    concerns :exportable

    member do
      get 'dc', to: 'catalog#dc'
      get 'ds/:dsid', to: 'catalog#ds', as: 'ds'
      get 'manage_release', to: 'catalog#manage_release'
    end
  end

  get 'catalog/:id/bulk_upload_form',    :to => 'catalog#bulk_upload_form',  :as => 'bulk_upload_form'
  get 'catalog/:id/bulk_jobs_index',     :to => 'catalog#bulk_jobs_index',   :as => 'bulk_jobs_index'
  get 'catalog/:id/bulk_status_help',    :to => 'catalog#bulk_status_help',  :as => 'bulk_status_help'
  get 'catalog/:id/:time/bulk_jobs_xml', :to => 'catalog#bulk_jobs_xml',     :as => 'bulk_jobs_xml'
  get 'catalog/:id/:time/bulk_jobs_log', :to => 'catalog#bulk_jobs_log',     :as => 'bulk_jobs_log'
  get 'catalog/:id/bulk_jobs_help',      :to => 'catalog#bulk_jobs_help',    :as => 'bulk_jobs_help'
  get 'catalog/:id/:time/bulk_jobs_csv', :to => 'catalog#bulk_jobs_csv',     :as => 'bulk_jobs_csv'
  post 'catalog/:id/upload',             :to => 'catalog#upload',            :as => 'upload'
  delete 'catalog/:id/bulk_jobs_delete', :to => 'catalog#bulk_jobs_delete',  :as => 'bulk_jobs_delete'
  match 'catalog',      :via => [:get, :post], :to => redirect { |params, req| req.fullpath.sub(%r{^/catalog}, '/view') }, as: 'search_catalog_redirect'
  match 'catalog/*all', :via => [:get, :post], :to => redirect { |params, req| req.fullpath.sub(%r{^/catalog}, '/view') }, as: 'catalog_redirect'

  match 'report',          :to => 'report#index',    :via => [:get, :post], :as => 'report'
  match 'report/data',     :to => 'report#data',     :via => [:get, :post], :as => 'report_data'
  match 'report/download', :to => 'report#download', :via => [:get, :post], :as => 'report_download'
  match 'report/bulk',     :to => 'report#bulk',     :via => [:get, :post], :as => 'report_bulk'
  match 'report/pids',     :to => 'report#pids',     :via => [:get, :post], :as => 'report_pids'
  match 'report/reset',    :to => 'report#reset',    :via => [:post],       :as => 'report_reset'
  match 'report/workflow_grid', :to => 'report#workflow_grid', :via => [:get, :post], :as => 'report_workflow_grid'

  ##
  # This route provides access to CatalogController#facet so facet links can be
  # generated.
  resource :report, controller: 'report', only: [] do
    concerns :searchable
  end

  match 'apo/is_valid_role_list', :to => 'apo#is_valid_role_list_endpoint', :via => [:get, :post], :as => 'is_valid_role_list'

  root :to => 'catalog#index'

  namespace :report do
    get 'workflow_grid'
  end

  resources :apo do
    collection do
      match :register, :via => [:get, :post]
      get :spreadsheet_template
    end
    member do
      get 'apo_ui'
      get 'delete_role'
      post 'add_collection'
      get  'delete_collection'
      post 'update_title'
      post 'update_creative_commons'
      post 'update_use'
      post 'update_copyright'
      post 'update_default_object_rights'
      post 'add_roleplayer'
      post 'update_desc_metadata'
      post :update
      match :register_collection, :via => [:get, :post]
    end
  end

  resources :items do
    get :register, :on => :collection
    resource :content_type, only: [:show, :update]
    member do
      get 'purl_preview'
      get 'discoverable'
      get 'refresh_metadata'
      get 'schema_validate',  :action => :schema_validation, :as => 'schema_validation'
      get 'remediate_mods'
      get 'mods'
      get 'remove_duplicate_encoding'
      get 'detect_duplicate_encoding'
      get 'create_minimal_mods'
      get  'workflows/:wf_name', :action => :workflow_view,         :as => 'workflow_view'
      post 'workflows/:wf_name', :action => :workflow_update,       :as => 'workflow_update'
      get  'workflow/history',   :action => :workflow_history_view, :as => 'workflow_history_view'
      post 'embargo',            :action => :embargo_update,        :as => 'embargo_update'
      get 'embargo_form'
      post 'datastream',         :action => :datastream_update,     :as => 'datastream_update'
      get 'file',                :action => :get_file,          :as => 'get_file'
      get 'file_list',           :action => :file,              :as => 'file'
      post 'file/attributes',    :action => :update_attributes, :as => 'update_attributes'
      match 'close_version_ui',  :action => :close_version_ui,  :as => 'close_version_ui', :via => [:get, :post]
      match 'open_version_ui',   :action => :open_version_ui,   :as => 'open_version_ui',  :via => [:get, :post]
      post 'version/open',        :action => :open_version,      :as => 'open_version'
      get 'source_id_ui'
      get 'tags_ui'
      get 'catkey_ui'
      match 'tags',      :via => [:get, :post]
      match 'tags_bulk', :via => [:get, :post]
      get 'collection_ui'
      get 'collection/delete',   :action => :remove_collection, :as => 'remove_collection'
      post 'collection/add',     :action => :add_collection,    :as => 'add_collection'
      post 'collection/set',     :action => :set_collection,    :as => 'set_collection'
      get 'purge',               :action => :purge_object
      get  'rights'
      post 'prepare'
      post 'set_rights'
      get 'set_governing_apo_ui'
      post 'set_governing_apo'
      get  'preserved_file', :action => :get_preserved_file
      post :release_hold
      match :add_workflow, :action => :add_workflow, :as => 'add_workflow', :via => [:get, :post]
      get :apply_apo_defaults
      get :fix_missing_provenance
      match :update_resource, :action => :update_resource, :as => 'update_resource', :via => [:get, :post]
    end
  end

  namespace :items do
    post 'version/close',  :action => :close_version, :as => 'close_version'
    post 'version/open',   :action => :open_version,  :as => 'open_version'
    post 'source_id'
    post 'catkey'
    post 'add_collection'
    post 'set_collection'
  end

  namespace :registration do
    get '/', :action => :form
    get 'tracksheet'
    get 'collection_list'
    get 'workflow_list'
    get 'rights_list'
    get 'suggest_project', :action => 'autocomplete', :field => 'project_tag_ssim'
  end

  namespace :auth do
    get 'groups'
    post 'remember_impersonated_groups'
    get 'forget_impersonated_groups'
  end

  namespace :dor do
    match 'republish/:pid', :action => :republish,                 :via => [:get, :post]
    match 'reindex/:pid',   :action => :reindex, :as => 'reindex', :via => [:get, :post]
    resources :objects, :only => :create # we only implement create for object registration
  end

  get 'index_queue/depth', to: 'index_queue#depth'

  namespace :workflow_service do
    get '/:pid/closeable',
        action: 'closeable',
        as: 'closeable',
        defaults: { format: :json }
    get '/:pid/openable',
        action: 'openable',
        as: 'openable',
        defaults: { format: :json }
    get '/:pid/published',
        action: 'published',
        as: 'published',
        defaults: { format: :json }
    get '/:pid/submitted',
        action: 'submitted',
        as: 'submitted',
        defaults: { format: :json }
    get '/:pid/accessioned',
        action: 'accessioned',
        as: 'accessioned',
        defaults: { format: :json }
  end

end
