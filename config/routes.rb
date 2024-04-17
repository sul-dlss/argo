# frozen_string_literal: true

Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/queues'

  get '/is_it_working' => 'ok_computer/ok_computer#show', :defaults => { check: 'default' }

  resources :bulk_actions, only: %i[index new destroy] do
    member do
      get :file
    end
    scope module: 'bulk_actions' do
      collection do
        # In the order they appear in the dropdown
        resource :manage_release_job, only: %i[new create]
        resource :reindex_job, only: %i[new create]
        resource :republish_job, only: %i[new create]
        resource :purge_job, only: %i[new create]
        resource :add_workflow_job, only: %i[new create]

        resource :open_version_job, only: %i[new create]
        resource :close_version_job, only: %i[new create]
        resource :governing_apo_job, only: %i[new create]
        resource :apply_apo_defaults_job, only: %i[new create]
        resource :rights_job, only: %i[new create]
        resource :license_and_rights_statement_job, only: %i[new create]
        resource :catalog_record_id_and_barcode_job, only: %i[new create]
        resource :refresh_mods_job, only: %i[new create]
        resource :content_type_job, only: %i[new create]
        resource :collection_job, only: %i[new create]

        resource :virtual_object_job, only: %i[new create]
        resource :catalog_record_id_and_barcode_csv_job, only: %i[new create]
        resource :source_id_csv_job, only: %i[new create]
        resource :export_tag_job, only: %i[new create]
        resource :import_tag_job, only: %i[new create]
        resource :export_structural_job, only: %i[new create]
        resource :import_structural_job, only: %i[new create]
        resource :manage_embargo_job, only: %i[new create]
        resource :register_druid_job, only: %i[new create]

        resource :descriptive_metadata_export_job, only: %i[new create]
        resource :descriptive_metadata_import_job, only: %i[new create]
        resource :download_mods_job, only: %i[new create]
        resource :checksum_report_job, only: %i[new create]
        resource :validate_cocina_descriptive_job, only: %i[new create]
        resource :tracking_sheet_report_job, only: %i[new create]
        resource :export_cocina_json_job, only: %i[new create]
      end
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
    member do
      get 'lazy_nonproject_tag_facet'
      get 'lazy_project_tag_facet'
      get 'lazy_wps_workflow_facet'
    end
  end

  resources :solr_documents, only: [:show], controller: 'catalog', path: '/view' do
    concerns :exportable
  end

  match 'catalog', via: %i[get post], to: redirect { |_params, req|
                                            req.fullpath.sub(%r{^/catalog}, '/view')
                                          }, as: 'search_catalog_redirect'
  match 'catalog/*all', via: %i[get post], to: redirect { |_params, req|
                                                 req.fullpath.sub(%r{^/catalog}, '/view')
                                               }, as: 'catalog_redirect'

  match 'report', to: 'report#index', via: %i[get post], as: 'report'
  match 'report/data', to: 'report#data', via: %i[get post], as: 'report_data'
  match 'report/download', to: 'report#download', via: %i[get post], as: 'report_download'
  post 'report/reset', to: 'report#reset', as: 'report_reset'
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

  resources :collections, only: :update do
    member do
      get :count
    end
    collection do
      get :exists
    end
  end

  resources :apo, only: %i[new update create edit] do
    resources :collections, only: %i[new create]
    collection do
      get :spreadsheet_template
    end
    member do
      get 'delete_collection'
      get 'count_collections'
      get 'count_items'
      get 'registration_options'
    end
  end

  resources :apos, only: [] do
    resource :bulk_jobs, only: :destroy
    resources :bulk_jobs, only: :index do
      collection do
        get 'status_help'
        get ':time/log', action: :show, as: 'show'
      end
    end
    resources :uploads, only: %i[new create]
  end

  resource :tags, only: [] do
    collection do
      get 'search'
    end
  end

  resources :items, only: %i[show update] do
    resources 'files', only: %i[index], constraints: { id: /.*/ } do
      member do
        get 'preserved'
      end

      collection do
        get 'download'
      end
    end

    resource :publish, only: %i[create]
    resource :content_type, only: %i[edit update]
    resource :structure, only: %i[show update] do
      collection do
        get 'hierarchy'
      end
    end
    resource :descriptive, only: %i[show edit update]
    resource :technical, only: %i[show]
    resource :events, only: %i[show]
    resource :cocina_object, only: %i[show]
    resource :serials, only: %i[edit update]

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

    resource :manage_release, only: :show
    resources :metadata, only: [] do
      collection do
        get 'full_dc'
        get 'full_dc_xml'
        get 'descriptive'
      end
    end

    resource :catalog_record_id, only: %i[edit update]
    resource :embargo, only: %i[new edit update]

    member do
      post 'refresh_metadata'
      get 'source_id_ui'
      get 'collection_ui'
      get 'edit_barcode'
      get 'show_barcode'
      get 'edit_copyright'
      get 'show_copyright'
      get 'edit_rights'
      get 'show_rights'
      get 'edit_use_statement'
      get 'show_use_statement'
      get 'edit_license'
      get 'show_license'
      get 'collection/delete', action: :remove_collection, as: 'remove_collection'
      post 'collection/add', action: :add_collection, as: 'add_collection'
      delete 'purge', action: :purge_object
      get 'set_governing_apo_ui'
      post 'set_governing_apo'
      post :apply_apo_defaults
      post 'source_id'
    end
  end

  resources :agreements, only: %i[show new create]

  resource :registration, only: %i[show create] do
    collection do
      get 'tracksheet'
      get 'source_id'
      get 'catalog_record_id'
      get 'spreadsheet'
      get 'suggest_project', action: 'autocomplete'
    end
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
    get 'webauth/login' => 'login#login', :as => :new_user_session
    match 'webauth/logout' => 'devise/sessions#destroy', :as => :destroy_user_session,
          :via => Devise.mappings[:user].sign_out_via
  end

  namespace :dor do
    match 'reindex/:druid', action: :reindex, as: 'reindex', via: %i[get post]
  end

  resources :workflow_service, only: [] do
    member do
      get :lock
      get :published
    end
  end
end
