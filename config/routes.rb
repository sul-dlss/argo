# frozen_string_literal: true

Rails.application.routes.draw do
  get '/is_it_working' => 'ok_computer/ok_computer#show', defaults: { check: 'default' }

  resources :bulk_actions, except: %i[edit show update] do
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

  match 'catalog',      via: %i[get post], to: redirect { |params, req| req.fullpath.sub(%r{^/catalog}, '/view') }, as: 'search_catalog_redirect'
  match 'catalog/*all', via: %i[get post], to: redirect { |params, req| req.fullpath.sub(%r{^/catalog}, '/view') }, as: 'catalog_redirect'

  match 'report',          to: 'report#index',    via: %i[get post], as: 'report'
  match 'report/data',     to: 'report#data',     via: %i[get post], as: 'report_data'
  match 'report/download', to: 'report#download', via: %i[get post], as: 'report_download'
  match 'report/bulk',     to: 'report#bulk',     via: %i[get post], as: 'report_bulk'
  match 'report/pids',     to: 'report#pids',     via: %i[get post], as: 'report_pids'
  match 'report/reset',    to: 'report#reset',    via: [:post], as: 'report_reset'
  get 'report/workflow_grid', to: 'report#workflow_grid', as: 'report_workflow_grid'

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

  resources :apo, only: %i[new update create edit] do
    resources :collections, only: %i[new create]
    collection do
      get :spreadsheet_template
    end
    member do
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
    resource :bulk_jobs, only: :destroy
    resources :bulk_jobs, only: :index do
      collection do
        get 'status_help'
        get 'help'
        get ':time/log', action: :show, as: 'show'
      end
    end
    resources :uploads, only: %i[new create]
  end

  resources :items, only: [] do
    resources 'files', only: %i[index show], constraints: { id: /.*/ } do
      member do
        get 'preserved'
      end
    end

    get :register, on: :collection
    resource :content_type, only: %i[show update]

    resources :workflows, only: %i[new create show update] do
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

    resource :tags, only: %i[edit update]

    member do
      get 'purl_preview'
      post 'refresh_metadata'
      get 'schema_validate', action: :schema_validation, as: 'schema_validation'
      get 'mods'
      post 'embargo', action: :embargo_update, as: 'embargo_update'
      get 'embargo_form'
      post 'datastream', action: :datastream_update, as: 'datastream_update'
      get 'source_id_ui'
      get 'catkey_ui'
      get 'collection_ui'
      get 'collection/delete',   action: :remove_collection, as: 'remove_collection'
      post 'collection/add',     action: :add_collection,    as: 'add_collection'
      post 'collection/set',     action: :set_collection,    as: 'set_collection'
      delete 'purge', action: :purge_object
      get  'rights'
      post 'set_rights'
      get 'set_governing_apo_ui'
      post 'set_governing_apo'
      post :apply_apo_defaults
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

  scope path: '/settings' do
    resources :tokens, only: %i[index create]
  end

  devise_for :users, skip: %i[registrations passwords sessions]
  devise_scope :user do
    get 'webauth/login' => 'login#login', as: :new_user_session
    match 'webauth/logout' => 'devise/sessions#destroy', :as => :destroy_user_session, :via => Devise.mappings[:user].sign_out_via
  end

  namespace :dor do
    match 'republish/:pid', action: :republish, via: %i[get post]
    match 'reindex/:pid',   action: :reindex, as: 'reindex', via: %i[get post]
    resources :objects, only: :create # we only implement create for object registration
  end

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
