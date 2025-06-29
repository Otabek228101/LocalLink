defmodule LocallinkApiWeb.AuthController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Accounts
  alias LocallinkApi.Guardian

  def register(conn, %{"user" => user_params}) do
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
            last_name: user.last_name
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(changeset)})
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user)

        conn
        |> json(%{
          message: "Login successful",
          token: token,
          user: %{
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name
          }
        })

      {:error, :unauthorized} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid email or password"})
    end
  end

  def me(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

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
        total_jobs_completed: user.total_jobs_completed
      }
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
