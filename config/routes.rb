# frozen_string_literal: true
Samson::Application.routes.draw do
  root to: 'projects#index'

  namespace :api do
    resources :deploys, only: [:index, :show] do
      collection do
        get :active_count
      end
    end

    resources :deploy_groups, only: [:index]

    resources :projects, only: [:index] do
      resources :automated_deploys, only: [:create]
      resources :builds, only: [:create]
      resources :deploys, only: [:index]
      resources :stages, only: [:index] do
        member do
          get :deploy_groups, to: 'deploy_groups#index'
        end
      end
    end

    resources :stages, only: [] do
      resources :deploys, only: [:index]
      post :clone, to: 'stages#clone'
    end

    resources :locks, only: [:index, :create, :destroy]
    delete '/locks', to: 'locks#destroy_via_resource'

    resources :users, only: [:destroy]
  end

  resources :projects do
    resources :jobs, only: [:index, :show, :destroy]

    resources :builds, only: [:show, :index, :new, :create, :edit, :update] do
      member do
        post :build_docker_image
      end
    end

    resource :build_command, only: [:show, :update]

    resources :deploys, only: [:index, :show, :destroy] do
      collection do
        get :active
      end

      member do
        post :buddy_check
        get :changeset
      end
    end

    resources :releases, only: [:show, :index, :new, :create], id: /v(#{Samson::RELEASE_NUMBER})/

    resources :stages do
      collection do
        patch :reorder
      end

      member do
        get :clone, to: 'stages#clone'
      end

      resources :deploys, only: [:new, :create] do
        collection do
          post :confirm
        end
      end

      resource :commit_statuses, only: [:show]
    end

    resource :changelog, only: [:show]
    resource :stars, only: [:create]
    resources :webhooks, only: [:index, :create, :destroy]
    resources :outbound_webhooks, only: [:create, :destroy]
    resources :references, only: [:index]
    resources :user_project_roles, only: [:index]

    member do
      get :deploy_group_versions
    end
  end

  resources :user_project_roles, only: [:index, :create]
  resources :streams, only: [:show]
  resources :locks, only: [:create, :destroy]

  resources :deploys, only: [:index] do
    collection do
      get :active
    end
  end

  resource :profile, only: [:show, :update]

  resources :users, only: [:index, :show, :update, :destroy]

  resources :access_tokens, only: [:index, :new, :create, :destroy]

  resources :environments, except: [:edit]

  resources :audits, only: [:index]

  resources :commands, except: [:edit]

  resources :deploy_groups do
    member do
      post :deploy_all
      get :create_all_stages_preview
      post :create_all_stages
      post :merge_all_stages
      post :delete_all_stages
    end
  end

  resources :secrets, except: [:edit]
  resources :secret_sharing_grants, except: [:edit, :update]

  resources :users, only: [] do
    resource :user_merges, only: [:new, :create]
  end

  resources :vault_servers, except: [:edit] do
    member do
      post :sync
    end
  end

  get '/auth/github/callback', to: 'sessions#github'
  get '/auth/google/callback', to: 'sessions#google'
  post '/auth/ldap/callback', to: 'sessions#ldap'
  get '/auth/gitlab/callback', to: 'sessions#gitlab'
  get '/auth/bitbucket/callback', to: 'sessions#bitbucket'
  get '/auth/failure', to: 'sessions#failure'

  get '/jobs/enabled', to: 'jobs#enabled', as: :enabled_jobs

  get '/login', to: 'sessions#new'
  get '/logout', to: 'sessions#destroy'

  resources :csv_exports, only: [:index, :new, :create, :show]
  resources :dashboards, only: [:show] do
    member do
      get :deploy_groups
    end
  end

  namespace :integrations do
    post "/circleci/:token" => "circleci#create", as: :circleci_deploy
    post "/travis/:token" => "travis#create", as: :travis_deploy
    post "/semaphore/:token" => "semaphore#create", as: :semaphore_deploy
    post "/tddium/:token" => "tddium#create", as: :tddium_deploy
    post "/jenkins/:token" => "jenkins#create", as: :jenkins_deploy
    post "/buildkite/:token" => "buildkite#create", as: :buildkite_deploy
    post "/github/:token" => "github#create", as: :github_deploy
  end

  get '/ping', to: 'ping#show'

  resources :access_requests, only: [:new, :create]

  mount SseRailsEngine::Engine, at: '/streaming'

  use_doorkeeper # adds oauth/* routes
  resources :oauth_test, only: [:index, :show] if %w[development test].include?(Rails.env)
end
