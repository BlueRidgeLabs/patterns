# frozen_string_literal: true

require 'sidekiq/web'
Patterns::Application.routes.draw do
  resources :cash_cards
  resources :budgets do
    collection do
      post '/transaction/create',
           action: :create_transaction,
           as: :create_transaction,
           defaults: { format: 'js' }
    end
  end
  resources :digital_gifts do
    resources :comments, controller: 'comments'
    collection do
      post 'sent/:id',
           action: :sent,
           as: :sent,
           defaults: { format: 'js' }

      get 'api_create',
          action: :api_create,
          as: :api_create,
          defaults: { format: 'json' }

      post 'webhook',
           action: :webhook,
           as: :webhook,
           defaults: { format: 'json' }
    end
  end

  resources :activation_calls do
    collection do
      get 'activate/:token',
          action: :activate,
          as: :activate,
          defaults: { format: 'xml' }
      get 'check/:token',
          action: :check,
          as: :check,
          defaults: { format: 'xml' }
      post 'callback/:token',
           action: :callback,
           as: :callback,
           defaults: { format: 'xml' }
    end
  end

  resources :gift_cards do
    collection do
      get 'template',
          action: :template,
          as: :template,
          defaults: { format: 'xlsx' }
      get 'signout_sheet',
          action: :signout_sheet,
          as: :signout_sheet,
          defaults: { format: 'xlsx' }
      post 'upload',
           action: :upload,
           as: :upload
      post 'check/:id',
           action: :check,
           as: :check,
           defaults: { format: 'json' }
      post 'change_user/:id',
           action: :change_user,
           as: :change_user,
           defaults: { format: 'json' }
      get 'preloaded',
          action: :preloaded,
          as: :preloaded
      post 'preload',
           action: 'preload',
           as: 'preload'
      post 'activate',
           action: 'activate',
           as: 'activate'
    end
  end

  resource :inbox, controller: 'inbox', only: %i[show create]
  resources :rewards do
    collection do
      post 'assign', action: :assign, as: :assign
      get 'recent_signups', action: :recent_signups, as: :recent_signups
      get 'modal/:giftable_type/:giftable_id', action: :modal, as: :modal
    end
  end

  resources :mailchimp_updates
  namespace :public do
    resources :people, only: %i[new create deactivate] do
      get '/consent/:token', to: 'people#consent', as: :consent
      get '/deactivate/:token', to: 'people#deactivate', as: :deactivate
    end
  end

  resources :invitations do
    resources :comments, controller: 'comments'
  end

  resources :research_sessions, path: :sessions, has_many: :invitations do
    get 'clone', to: 'research_sessions#clone', as: :clone
    resources :comments, controller: 'comments'
    get 'invitations_panel',
        to: 'research_sessions#invitations_panel',
        as: :invitations_panel
    get 'add_person/:person_id',
        to: 'research_sessions#add_person',
        as: :add_person
    get 'remove_person/:person_id',
        to: 'research_sessions#remove_person',
        as: :remove_person

    resources :invitations do
      collection do
        post ':id/event/:event',
             to: 'invitations#event',
             as: :event

        get ':id/confirm/(:token)',
            to: 'invitations#confirm',
            as: :remote_confirm

        get ':id/cancel/(:token)',
            to: 'invitations#cancel',
            as: :remote_cancel
      end
      resources :comments, controller: 'comments'
    end
  end

  resources :sms_invitations, only: [:create]

  # simple session based cart for storing people ids.
  resources :cart, path: :cart do
    collection do
      post 'create', to: 'cart#create', as: :create
      get 'add/:person_id', to: 'cart#add', as: :add_person
      get 'delete(/:person_id(/:all))', to: 'cart#delete', as: :delete_person

      post 'add_user(/:user_id)', to: 'cart#add_user', as: :add_user
      post 'delete_user/:user_id', to: 'cart#delete_user', as: :delete_user

      post '(:id)/change', to: 'cart#change_cart', as: :change
      get 'change(/:id)', to: 'cart#change_cart', as: :change_get
    end
    resources :comments, controller: 'comments'
  end

  get '/consent/:token', to: 'public/people#consent', as: :consent
  get 'registration', to: 'public/people#new'

  post '/api/update_person', to: 'public/people#update', as: :update_post
  get '/api/update_person', to: 'public/people#update', as: :update_get

  post '/api/create_person', to: 'public/people#api_create', as: :api_create
  get '/api/show', to: 'public/people#show', as: :public_show_person

  get 'taggings/', as: :tag_index, to: 'taggings#index'
  get 'taggings/create', as: :tag_create
  get 'taggings/destroy', as: :tag_destroy
  get 'taggings/search', as: :tag_search

  get 'mailchimp_export/index'
  get 'mailchimp_export/create'

  devise_for :users

  scope '/admin' do
    resources :teams
    resources :users
    get 'map', to: 'people#map', as: :people_map
    get 'people_amount', to: 'people#amount', as: :people_amount
    get 'finance', to: 'users#finance', as: :finance_code
    get 'changes', to: 'users#changes', as: :user_changes
  end

  get 'dashboard/index'

  resources :comments
  resources :taggings, only: %i[create destroy]

  get 'calendar/event_slots.json(:token)', to: 'calendar#event_slots', defaults: { format: 'json' }

  get 'calendar/reservations.json(:token)', to: 'calendar#reservations', defaults: { format: 'json' }
  get 'calendar/events.json', to: 'calendar#events', defaults: { format: 'json' }

  get '/calendar/(:id)', to: 'calendar#show', as: :calendar
  get '/calendar/(:token)/feed/', to: 'calendar#feed', defaults: { format: 'ics' }

  get '/calendar/(:token)/admin_feed/', to: 'calendar#admin_feed', defaults: { format: 'ics' }

  get '/calendar/show_actions/:id/(:token)',
      to: 'calendar#show_actions',
      defaults: { format: 'js' },
      as: :calendar_show_actions

  get '/calendar/show_reservation/:id/(:token)',
      to: 'calendar#show_reservation',
      defaults: { format: 'js' },
      as: :calendar_show_reservation

  get '/calendar/show_invitation/:id/(:token)',
      to: 'calendar#show_invitation',
      defaults: { format: 'js' },
      as: :calendar_show_invitation

  get '/calendar/show_event/:id/(:token)',
      to: 'calendar#show_event',
      defaults: { format: 'js' },
      as: :calendar_show_event

  get  'search/index'
  get  'search/index_ransack'
  post 'search/index_ransack'
  post 'search/export_ransack'
  post 'search/export' # send search results elsewhere, i.e. Mailchimp
  post 'search/exportTwilio'
  get 'search/add_to_cart', to: 'search#add_to_cart', as: :search_add_to_cart
  get 'search/advanced', to: 'search#advanced', as: :advanced_search
  post 'search/advanced', to: 'search#advanced', as: :advanced_search_post

  get 'mailchimp_exports/index'

  resources :people do
    collection do
      delete 'consent/delete/:id', action: :delete_consent, as: :delete_consent
      patch 'consent/upload/:id', action: :upload_consent, as: :upload_consent
      get 'lookup/:uuid', action: :lookup, as: :lookup
      post 'create_sms'
      post ':person_id/deactivate', action: :deactivate, as: :deactivate
      post ':person_id/reactivate', action: :reactivate, as: :reactivate
    end
    resources :comments
    resources :rewards
  end
  # post "people/create_sms"

  get 'activate/:number/:code',
      to: 'gift_cards#activate',
      defaults: { format: 'xml' }

  post 'activate/:number/:code',
       to: 'gift_cards#activate',
       defaults: { format: 'xml' }

  get 'card_check/:number/:code/:expiration',
      to: 'gift_cards#card_check',
      defaults: { format: 'xml' }

  post 'card_check/:number/:code/:expiration',
       to: 'gift_cards#card_check',
       defaults: { format: 'xml' }

  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  root to: 'dashboard#index'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
