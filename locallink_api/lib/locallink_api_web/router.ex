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

  pipeline :optional_auth do
    plug LocallinkApi.Guardian.AuthPipeline
  end

  scope "/", LocallinkApiWeb do
    pipe_through :api
    get "/health", HealthController, :check
  end

  # Исправляем маршруты - убираем дублирование /api/v1
  scope "/api", LocallinkApiWeb do
    pipe_through :api
    post "/login", AuthController, :login
  end

  scope "/api/v1", LocallinkApiWeb do
    pipe_through :api
    post "/register", AuthController, :register
    get "/posts", PostController, :index
    get "/posts/:id", PostController, :show
  end

  scope "/api/v1", LocallinkApiWeb do
    pipe_through [:api, :auth]
    get "/me", AuthController, :me
    post "/posts", PostController, :create
    put "/posts/:id", PostController, :update
    delete "/posts/:id", PostController, :delete
    get "/my-posts", PostController, :my_posts
  end
end
