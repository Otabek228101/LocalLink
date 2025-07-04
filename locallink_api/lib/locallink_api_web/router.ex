defmodule LocallinkApiWeb.Router do
  use LocallinkApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug
  end

  pipeline :auth do
    plug LocallinkApi.Guardian.AuthPipeline
    plug Guardian.Plug.EnsureAuthenticated
  end

  scope "/", LocallinkApiWeb do
    pipe_through :api
    get "/health", HealthController, :check
  end

  scope "/api", LocallinkApiWeb do
    pipe_through :api
    post "/login", AuthController, :login
  end

  scope "/api/v1", LocallinkApiWeb do
    pipe_through :api
    post "/register", AuthController, :register
    get "/posts", PostController, :index
    get "/posts/:id", PostController, :show
    get "/hot-zones", PostController, :hot_zoness
    get "/events/available", PostController, :available_events
    get "/posts/:id/participants", PostController, :event_participants
    get "/posts/:id/stats", PostController, :event_stats
  end

  scope "/api/v1", LocallinkApiWeb do
    pipe_through [:api, :auth]
    get "/me", AuthController, :me
    post "/posts", PostController, :create
    put "/posts/:id", PostController, :update
    delete "/posts/:id", PostController, :delete
    get "/my-posts", PostController, :my_posts
    post "/reviews", ReviewController, :create
    get "/users/:user_id/reviews", ReviewController, :user_reviews
    get "/my-reviews", ReviewController, :my_reviews
    post "/posts/:id/join", PostController, :join_event      # Присоединиться к событию
    delete "/posts/:id/leave", PostController, :leave_event  # Покинуть событие
    get "/my-events", PostController, :my_events
    post "/posts/:post_id/offers/accept-price", OfferController, :accept_original_price
    post "/posts/:post_id/offers/counter-offer", OfferController, :make_counter_offer
    get "/posts/:post_id/offers", OfferController, :list_post_offers
    put "/offers/:id/accept", OfferController, :accept_offer
    put "/offers/:id/decline", OfferController, :decline_offer
    put "/offers/:id/complete", OfferController, :complete_offer
    get "/my-offers", OfferController, :my_offers
    get "/received-offers", OfferController, :received_offers
    get "/notifications/preferences", NotificationController, :get_preferences
    put "/notifications/preferences", NotificationController, :update_preferences
    post "/notifications/location", NotificationController, :update_location
    get "/notifications", NotificationController, :index
    put "/notifications/:id/read", NotificationController, :mark_as_read
    put "/notifications/:id/clicked", NotificationController, :mark_as_clicked
  end

  scope "/api/v1", LocallinkApiWeb do
    pipe_through [:api, LocallinkApi.Guardian.AuthPipeline]

    resources "/conversations", ConversationController, only: [:index, :create]

    get "/conversations/:conversation_id/messages", MessageController, :index
    post "/conversations/:conversation_id/messages", MessageController, :create
  end

  scope "/api/v1", LocallinkApiWeb do
    pipe_through [:api, LocallinkApi.Guardian.AuthPipeline]

    resources "/conversations", ConversationController, only: [:index, :show, :create] do
      resources "/messages", MessageController, only: [:index, :create]
    end
  end

end
