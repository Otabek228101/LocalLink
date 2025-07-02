defmodule LocallinkApiWeb.AuthController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Accounts
  alias LocallinkApi.Guardian

  require Logger

  # Используем fallback controller для обработки ошибок
  action_fallback LocallinkApiWeb.FallbackController

  def register(conn, %{"user" => user_params}) do
    Logger.info("Registration attempt for email: #{user_params["email"]}")

    case Accounts.create_user(user_params) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user)

        conn
        |> put_status(:created)
        |> json(%{
          message: "User created successfully",
          token: token,
          user: %{
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            phone: user.phone
          }
        })

      {:error, changeset} ->
        Logger.warn("Registration failed: #{inspect(changeset.errors)}")

        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: "Registration failed",
          errors: translate_errors(changeset)
        })
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    Logger.info("Login attempt for email: #{email}")

    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user)
        Logger.info("Login successful for user: #{user.id}")

        conn
        |> json(%{
          message: "Login successful",
          token: token,
          user: %{
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            phone: user.phone
          }
        })

      {:error, :unauthorized} ->
        Logger.warn("Login failed for email: #{email}")

        conn
        |> put_status(:unauthorized)
        |> json(%{
          error: "Invalid email or password",
          status: 401
        })
    end
  end

  def me(conn, _params) do
    # Этот action защищен auth pipeline, поэтому пользователь уже загружен
    case Guardian.Plug.current_resource(conn) do
      nil ->
        Logger.error("User resource not found in conn despite auth pipeline")

        conn
        |> put_status(:unauthorized)
        |> json(%{
          error: "User not authenticated",
          status: 401
        })

      user ->
        Logger.info("Profile request for user: #{user.id}")

        conn
        |> json(%{
          user: %{
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            phone: user.phone,
            location: user.location,
            skills: user.skills,
            availability: user.availability,
            rating: user.rating,
            total_jobs_completed: user.total_jobs_completed,
            is_verified: user.is_verified
          }
        })
    end
  end

  def register(conn, _params) do
    Logger.warn("Invalid registration parameters")

    conn
    |> put_status(:bad_request)
    |> json(%{
      error: "Invalid request format. Expected: {\"user\": {...}}",
      status: 400
    })
  end

  def login(conn, _params) do
    Logger.warn("Invalid login parameters")

    conn
    |> put_status(:bad_request)
    |> json(%{
      error: "Invalid request format. Expected: {\"email\": \"...\", \"password\": \"...\"}",
      status: 400
    })
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
