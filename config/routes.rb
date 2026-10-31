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

  resources :appeals, only: [ :index, :create ]

  get '/admin/events', to: 'admin/events#index', as: :admin_events
  get '/admin/events/new', to: 'admin/events#new', as: :new_admin_event
  post '/admin/events', to: 'admin/events#create'

  # AC-23.1: public help page so members can use the app without the dev team
  get '/support', to: 'support#show', as: :support

  get '/dashboard', to: 'dashboard#show', as: :dashboard
  get '/admin', to: 'admin#index', as: :admin
  # AC-25.01: CSV export of member points by school year
  get '/admin/export', to: 'admin#export', as: :admin_export

  get '/admin/members/:id', to: 'admin#show_member', as: :admin_member
  patch '/admin/members/:id/promote', to: 'admin#promote_member', as: :promote_admin_member
  patch '/admin/members/:id/revoke', to: 'admin#revoke_member', as: :revoke_admin_member
  get '/admin/members/:id/edit', to: 'admin#edit_member', as: :edit_admin_member
  patch '/admin/members/:id', to: 'admin#update_member'
  get '/admin/members/:id/delete', to: 'admin#delete_member', as: :delete_admin_member
  delete '/admin/members/:id', to: 'admin#destroy_member'

  namespace :admin do
    resources :appeals, only: [ :index, :show, :update ] do
      get :proof, on: :member
    end
    resources :categories
    resources :semesters, only: [ :create ]
    resources :events
    resources :semester_requirements, only: [ :index ]
    patch 'semesters/:semester_id/requirements',
        to: 'semester_requirements#update',
        as: :semester_requirements_update
  end

  # Member profile routes (show, edit, update)
  resources :members, only: [ :show, :edit, :update ]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get 'up' => 'rails/health#show', as: :rails_health_check
end
