defmodule LocallinkApi.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias LocallinkApi.Repo
  alias LocallinkApi.User

  @doc """
  Создает нового пользователя.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Получает пользователя по ID.
  """
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Получает пользователя по email.
  """
  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Аутентификация пользователя.
  """
  def authenticate_user(email, password) do
    user = get_user_by_email(email)

    cond do
      user && User.valid_password?(user, password) ->
        {:ok, user}
      user ->
        {:error, :unauthorized}
      true ->
        # Задержка для защиты от timing атак
        Process.sleep(100)
        {:error, :unauthorized}
    end
  end

  @doc """
  Обновляет пользователя.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Удаляет пользователя.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Получает список всех пользователей.
  """
  def list_users do
    Repo.all(User)
  end
end
