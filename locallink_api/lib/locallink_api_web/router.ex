defmodule LocallinkApiWeb.Router do
  use LocallinkApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug
  end

  pipeline :auth do
    plug LocallinkApi.Guardian.AuthPipeline
  end

  # Health check
  scope "/", LocallinkApiWeb do
    pipe_through :api
    get "/health", HealthController, :check
  end

  # Public API
  scope "/api/v1", LocallinkApiWeb do
    pipe_through :api

    post "/login",    AuthController, :login
    post "/register", AuthController, :register

    # Public posts
    get "/posts", PostController, :index
    get "/posts/:id", PostController, :show
  end

  # Protected API
  scope "/api/v1", LocallinkApiWeb do
    pipe_through [:api, :auth]

    # Auth
    get "/me", AuthController, :me

    # Posts
    post "/posts", PostController, :create
    put "/posts/:id", PostController, :update
    delete "/posts/:id", PostController, :delete

    # Offers
    post "/posts/:post_id/offers/accept-price", OfferController, :accept_original_price
    post "/posts/:post_id/offers/counter-offer", OfferController, :make_counter_offer
    get "/posts/:post_id/offers", OfferController, :list_for_post
    put "/offers/:id/accept", OfferController, :accept_offer
    put "/offers/:id/decline", OfferController, :decline_offer
    put "/offers/:id/complete", OfferController, :complete_offer
    get "/my-offers", OfferController, :list_my_offers

    # Reviews
    post "/reviews", ReviewController, :create
    get "/users/:user_id/reviews", ReviewController, :user_reviews
    get "/my-reviews", ReviewController, :my_reviews

    # Notifications
    get "/notifications/preferences", NotificationController, :get_preferences
    put "/notifications/preferences", NotificationController, :update_preferences
    post "/notifications/location", NotificationController, :update_location
    get "/notifications", NotificationController, :index
    put "/notifications/:id/read", NotificationController, :mark_as_read
    put "/notifications/:id/clicked", NotificationController, :mark_as_clicked

    # Chat \
    resources "/conversations", ConversationController, only: [:index, :show, :create] do
      resources "/messages", MessageController, only: [:index, :create]
    end
  end
end
