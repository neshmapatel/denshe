Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  get "up" => "rails/health#show", as: :rails_health_check

  scope module: :storefront do
    root "pages#home"

    get "shop", to: "products#index", as: :shop
    get "collections", to: "categories#index", as: :collections
    get "collections/:slug", to: "categories#show", as: :collection
    get "pieces/:slug", to: "products#show", as: :piece

    get "cart", to: "cart#show", as: :cart
    post "cart/items", to: "cart#create", as: :cart_items
    delete "cart/items/:slug", to: "cart#destroy", as: :cart_item
    get "checkout", to: "checkout#new", as: :checkout
    post "checkout", to: "checkout#create"
    get "checkout/payment", to: "checkout#payment", as: :checkout_payment

    get "jewellery-box", to: "pages#jewellery_box", as: :jewellery_box
    get "mystery-box", to: "pages#mystery_box", as: :mystery_box
    get "our-story", to: "pages#story", as: :story
    get "care-guide", to: "pages#care", as: :care
    get "contact", to: "pages#contact", as: :contact
  end

  get "search", to: redirect { |_params, request| "/shop?#{request.query_string}" }
end
