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
    get "/hot-zones", PostController, :hot_zones
  end

  scope "/api/v1", LocallinkApiWeb do
    pipe_through [:api, :auth]
    get "/me", AuthController, :me
    post "/posts", PostController, :create
    put "/posts/:id", PostController, :update
    delete "/posts/:id", PostController, :delete
    get "/my-posts", PostController, :my_posts
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
