defmodule LocallinkApiWeb.Router do
  use LocallinkApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug
  end

  pipeline :auth do
    plug LocallinkApi.Guardian.AuthPipeline
  end

  # Публичные маршруты
  scope "/api", LocallinkApiWeb do
    pipe_through :api

    # Аутентификация
    post "/register", AuthController, :register
    post "/login", AuthController, :login

    # Публичные посты (просмотр без авторизации)
    get "/posts", PostController, :index
    get "/posts/:id", PostController, :show
  end

  # Защищенные маршруты
  scope "/api", LocallinkApiWeb do
    pipe_through [:api, :auth]

    # Пользователь
    get "/me", AuthController, :me

    # Посты (требуют авторизации)
    post "/posts", PostController, :create
    put "/posts/:id", PostController, :update
    delete "/posts/:id", PostController, :delete
    get "/my-posts", PostController, :my_posts
  end
end
