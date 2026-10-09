# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'home#index'

  # OmniAuth routes
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
  delete '/logout', to: 'sessions#destroy', as: :logout

  # Check-in page + the button's save request
  get  'events/:id/check_in', to: 'check_ins#show', as: :event_check_in
  post 'events/:id/check_in', to: 'check_ins#create'

  resources :appeals, only: [ :index ]

  get '/admin/events', to: 'admin/events#index', as: :admin_events
  get '/admin/events/new', to: 'admin/events#new', as: :new_admin_event
  post '/admin/events', to: 'admin/events#create'

  get '/dashboard', to: 'dashboard#show', as: :dashboard
  get '/admin', to: 'admin#index', as: :admin

  get '/admin/members/:id', to: 'admin#show_member', as: :admin_member
  patch '/admin/members/:id/promote', to: 'admin#promote_member', as: :promote_admin_member

  # Member profile routes (show, edit, update)
  resources :members, only: [ :show, :edit, :update ]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get 'up' => 'rails/health#show', as: :rails_health_check
end
