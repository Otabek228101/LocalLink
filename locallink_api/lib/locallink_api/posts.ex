defmodule LocallinkApi.Posts do
  @moduledoc "The Posts context."

  import Ecto.Query, warn: false
  alias LocallinkApi.{Repo, Post, User}

  @doc "Список всех постов с возможностью фильтрации"
  def list_posts(filters \\ %{}) do
    Post
    |> filter_by_category(filters[:category])
    |> filter_by_location(filters[:location])
    |> filter_by_radius(filters[:lat], filters[:lng], filters[:radius_km])
    |> filter_by_active(filters[:active])
    |> order_by(desc: :inserted_at)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  @doc "Получить один пост по ID"
  def get_post(id) do
    case Repo.get(Post, id) do
      nil  -> {:error, :not_found}
      post -> {:ok, Repo.preload(post, :user)}
    end
  end

  @doc "Создать новый пост и запустить нотификацию"
  def create_post(%User{} = user, attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
    |> case do
      {:ok, post} ->
        Task.start(fn -> LocallinkApi.Notifications.notify_nearby_users(post.id) end)
        {:ok, post}
      error ->
        error
    end
  end

  @doc "Обновить пост"
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  @doc "Удалить пост"
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  @doc "Посты конкретного пользователя"
  def get_user_posts(user_id) do
    Post
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  # === Вспомогательные фильтры ===

  defp filter_by_category(query, nil), do: query
  defp filter_by_category(query, cat), do: where(query, [p], p.category == ^cat)

  defp filter_by_location(query, nil), do: query
  defp filter_by_location(query, loc), do: where(query, [p], ilike(p.location, ^"%#{loc}%"))

  defp filter_by_radius(query, nil, nil, _), do: query
  defp filter_by_radius(query, _lat, _lng, nil), do: query
  defp filter_by_radius(query, lat, lng, radius_km) do
    point = %Geo.Point{coordinates: {lng, lat}, srid: 4326}
    where(query, [p], fragment("ST_DWithin(?, ST_SetSRID(ST_MakePoint(?, ?), 4326), ?)", p.coordinates, ^lng, ^lat, ^radius_km * 1000))
  end

  defp filter_by_active(query, nil), do: query
  defp filter_by_active(query, true), do: where(query, [p], p.is_active == true)
  defp filter_by_active(query, false), do: where(query, [p], p.is_active == false)
end
