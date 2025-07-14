# frozen_string_literal: true

Salla::Engine.routes.draw do
  namespace :admin do
    resources :banners, only: [:index, :create, :update, :destroy]
  end

  get '/banner', to: 'banners#index'
end
