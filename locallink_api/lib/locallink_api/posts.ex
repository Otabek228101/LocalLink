defmodule LocallinkApi.Posts do
  @moduledoc """
  The Posts context.
  """

  import Ecto.Query, warn: false
  alias LocallinkApi.Repo
  alias LocallinkApi.Post

  @doc """
  Получает список постов с фильтрацией.
  """
  def list_posts(filters \\ %{}) do
    Post
    |> filter_by_category(filters[:category])
    |> filter_by_location(filters[:location])
    |> filter_by_active(filters[:active])
    |> order_by(desc: :inserted_at)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  @doc """
  Получает пост по ID.
  """
  def get_post(id) do
    case Repo.get(Post, id) do
      nil -> {:error, :not_found}
      post -> {:ok, Repo.preload(post, :user)}
    end
  end

  @doc """
  Создает новый пост.
  """
  def create_post(user, attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Обновляет пост.
  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Удаляет пост.
  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  @doc """
  Получает посты пользователя.
  """
  def get_user_posts(user_id) do
    Post
    |> where([p], p.user_id == ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  # Приватные функции для фильтрации

  defp filter_by_category(query, nil), do: query
  defp filter_by_category(query, category) do
    where(query, [p], p.category == ^category)
  end

  defp filter_by_location(query, nil), do: query
  defp filter_by_location(query, location) do
    # Здесь можно добавить более сложную логику для геолокации
    where(query, [p], ilike(p.location, ^"%#{location}%"))
  end

  defp filter_by_active(query, nil), do: where(query, [p], p.is_active == true)
  defp filter_by_active(query, active) do
    where(query, [p], p.is_active == ^active)
  end
end
