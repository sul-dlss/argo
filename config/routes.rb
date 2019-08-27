# frozen_string_literal: true

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

  resources :solr_documents, only: [:show], controller: 'catalog', path: '/view' do
    concerns :exportable

    member do
      get 'dc', to: 'catalog#dc'
      get 'ds/:dsid', to: 'catalog#ds', as: 'ds'
      get 'manage_release', to: 'catalog#manage_release'
    end
  end

  match 'catalog',      via: [:get, :post], to: redirect { |params, req| req.fullpath.sub(%r{^/catalog}, '/view') }, as: 'search_catalog_redirect'
  match 'catalog/*all', via: [:get, :post], to: redirect { |params, req| req.fullpath.sub(%r{^/catalog}, '/view') }, as: 'catalog_redirect'

  match 'report',          to: 'report#index',    via: [:get, :post], as: 'report'
  match 'report/data',     to: 'report#data',     via: [:get, :post], as: 'report_data'
  match 'report/download', to: 'report#download', via: [:get, :post], as: 'report_download'
  match 'report/bulk',     to: 'report#bulk',     via: [:get, :post], as: 'report_bulk'
  match 'report/pids',     to: 'report#pids',     via: [:get, :post], as: 'report_pids'
  match 'report/reset',    to: 'report#reset',    via: [:post],       as: 'report_reset'
  match 'report/workflow_grid', to: 'report#workflow_grid', via: [:get, :post], as: 'report_workflow_grid'

  ##
  # This route provides access to CatalogController#facet so facet links can be
  # generated.
  resource :report, controller: 'report', only: [] do
    concerns :searchable
  end

  root to: 'catalog#index'

  namespace :report do
    get 'workflow_grid'
  end

  namespace :collections do
    get :exists
  end

  resources :apo, only: [:new, :update, :create, :edit] do
    resources :collections, only: [:new, :create]
    collection do
      get :spreadsheet_template
    end
    member do
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
    end
  end

  resources :apos, only: [] do
    resources :bulk_jobs, only: :index do
      collection do
        get 'status_help'
        get 'help'
        get ':time/log', action: :show, as: 'show'
      end
    end
  end

  resources :items, only: [] do
    resources 'uploads', only: [:new, :create]
    resources 'files', only: [:index, :show], constraints: { id: /.*/ } do
      member do
        get 'preserved'
      end
    end

    get :register, on: :collection
    resource :content_type, only: [:show, :update]

    resources :workflows, only: [:new, :create, :show, :update] do
      collection do
        get 'history'
      end
    end

    resources :versions, only: [] do
      collection do
        get 'close_ui'
        get 'open_ui'
        post 'open'
        post 'close'
      end
    end

    member do
      get 'purl_preview'
      get 'discoverable'
      get 'refresh_metadata'
      get 'schema_validate', action: :schema_validation, as: 'schema_validation'
      get 'remediate_mods'
      get 'mods'
      get 'remove_duplicate_encoding'
      get 'detect_duplicate_encoding'
      post 'embargo', action: :embargo_update, as: 'embargo_update'
      get 'embargo_form'
      post 'datastream',         action: :datastream_update,     as: 'datastream_update'

      post 'file/attributes',    action: :update_attributes, as: 'update_attributes'
      get 'source_id_ui'
      get 'tags_ui'
      get 'catkey_ui'
      match 'tags',      via: [:get, :post]
      match 'tags_bulk', via: [:get, :post]
      get 'collection_ui'
      get 'collection/delete',   action: :remove_collection, as: 'remove_collection'
      post 'collection/add',     action: :add_collection,    as: 'add_collection'
      post 'collection/set',     action: :set_collection,    as: 'set_collection'
      get 'purge',               action: :purge_object
      get  'rights'
      post 'set_rights'
      get 'set_governing_apo_ui'
      post 'set_governing_apo'
      post :release_hold
      get :apply_apo_defaults
      match :update_resource, action: :update_resource, as: 'update_resource', via: [:get, :post]
    end
  end

  namespace :items do
    post 'source_id'
    post 'catkey'
    post 'add_collection'
    post 'set_collection'
  end

  namespace :registration do
    get '/', action: :form
    get 'tracksheet'
    get 'collection_list'
    get 'workflow_list'
    get 'rights_list'
    get 'suggest_project', action: 'autocomplete', field: 'project_tag_ssim'
  end

  namespace :auth do
    get 'groups'
    post 'remember_impersonated_groups'
    get 'forget_impersonated_groups'
  end

  devise_for :users, skip: [:registrations, :passwords, :sessions]
  devise_scope :user do
    get 'webauth/login' => 'login#login', as: :new_user_session
    match 'webauth/logout' => 'devise/sessions#destroy', :as => :destroy_user_session, :via => Devise.mappings[:user].sign_out_via
  end

  namespace :dor do
    match 'republish/:pid', action: :republish, via: [:get, :post]
    match 'reindex/:pid',   action: :reindex, as: 'reindex', via: [:get, :post]
    resources :objects, only: :create # we only implement create for object registration
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
