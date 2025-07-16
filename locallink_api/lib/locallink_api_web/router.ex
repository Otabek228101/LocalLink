# lib/locallink_api_web/router.ex

defmodule LocallinkApiWeb.Router do
  use LocallinkApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug LocallinkApi.Guardian.AuthPipeline
  end

  # Health check at root
  scope "/", LocallinkApiWeb do
    pipe_through :api

    get "/health", HealthController, :check
  end

  scope "/api/v1", LocallinkApiWeb do
    pipe_through :api

    # Public endpoints
    post "/register", AuthController, :register
    post "/login",    AuthController, :login

    # Posts public
    get  "/posts",        PostController, :index
    get  "/posts/:id",    PostController, :show

    # Public reviews (для просмотра рейтингов)
    get  "/users/:user_id/reviews", ReviewController, :user_reviews

    pipe_through :auth

    # Authenticated
    get  "/me", AuthController, :me

    # Posts actions
    post   "/posts",        PostController, :create
    put    "/posts/:id",    PostController, :update
    delete "/posts/:id",    PostController, :delete

    # Offers nested under posts
    get    "/posts/:post_id/offers",                 OfferController, :list_for_post
    post   "/posts/:post_id/offers/accept-price",    OfferController, :accept_original_price
    post   "/posts/:post_id/offers/counter-offer",   OfferController, :make_counter_offer

    # Offer status updates
    put    "/offers/:id/accept",   OfferController, :accept_offer
    put    "/offers/:id/decline",  OfferController, :decline_offer
    put    "/offers/:id/complete", OfferController, :complete_offer

    # conversations & messages
    get  "/conversations",                 ConversationController, :index
    post "/conversations",                 ConversationController, :create
    get  "/conversations/:id",             ConversationController, :show

    get  "/conversations/:id/messages",    MessageController,      :index
    post "/conversations/:id/messages",    MessageController, :create

    # Reviews (authenticated actions)
    post   "/reviews",                        ReviewController, :create
    get    "/users/:user_id/reviews/detailed", ReviewController, :detailed_user_reviews
    get    "/reviews/my",                     ReviewController, :my_reviews

    # Notifications
    get    "/notifications/preferences",     NotificationController, :get_preferences
    put    "/notifications/preferences",     NotificationController, :update_preferences
    post   "/notifications/location",        NotificationController, :update_location
    get    "/notifications",                 NotificationController, :index
    put    "/notifications/:id/read",        NotificationController, :mark_as_read
    put    "/notifications/:id/clicked",     NotificationController, :mark_as_clicked
  end

  # Catch-all 404 for /api/v1
  scope "/api/v1", LocallinkApiWeb do
    match :*, "/*path", FallbackController, :not_found
  end
end
