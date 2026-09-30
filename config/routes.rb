Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  get "up" => "rails/health#show", as: :rails_health_check

  # Unlocks the storefront in this browser. /admin is never held.
  get "preview/close", to: "preview#destroy", as: :close_storefront_preview
  get "preview/:token", to: "preview#create", as: :storefront_preview

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
    get "checkout/success", to: "checkout#success", as: :checkout_success
    post "checkout/razorpay-order", to: "checkout#create_payment", as: :checkout_razorpay_order
    post "checkout/verify-payment", to: "checkout#verify_payment", as: :checkout_payment_verify
    post "checkout/payment-failed", to: "checkout#record_payment_failure", as: :checkout_payment_failure

    get "jewellery-box", to: "pages#jewellery_box", as: :jewellery_box
    get "mystery-box", to: "mystery_boxes#show", as: :mystery_box
    post "mystery-box", to: "mystery_boxes#create"
    get "mystery-box/details", to: "mystery_boxes#details", as: :mystery_box_details
    post "mystery-box/details", to: "mystery_boxes#place"
    get "our-story", to: "pages#story", as: :story
    get "care-guide", to: "pages#care", as: :care
    get "contact", to: "pages#contact", as: :contact
  end

  get "search", to: redirect { |_params, request| "/shop?#{request.query_string}" }
end
