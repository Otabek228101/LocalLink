defmodule LocallinkApi.Posts do
  @moduledoc """
  The Posts context.
  """

  import Ecto.Query, warn: false
  alias LocallinkApi.Repo
  alias LocallinkApi.Post

  @doc """
  Получает список постов с фильтрацией по параметрам и координатам.
  """
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

  @doc """
  Возвращает "горячие зоны" активности за последние 24 часа.
  """
  def hot_zones do
    query = """
    SELECT
      ST_AsGeoJSON(ST_Centroid(ST_Collect(coordinates))) AS center,
      COUNT(*) as post_count
    FROM posts
    WHERE inserted_at >= NOW() - INTERVAL '1 day'
    GROUP BY ST_SnapToGrid(coordinates, 0.01, 0.01)
    HAVING COUNT(*) > 5
    """

    case Ecto.Adapters.SQL.query(Repo, query, []) do
      {:ok, %{rows: rows}} ->
        Enum.map(rows, fn [geojson, count] ->
          %{center: Jason.decode!(geojson), post_count: count}
        end)

      error ->
        IO.inspect(error, label: "[HotZones Error]")
        []
    end
  end

  # Приватные функции фильтрации

  defp filter_by_category(query, nil), do: query
  defp filter_by_category(query, category), do:
    where(query, [p], p.category == ^category)

  defp filter_by_location(query, nil), do: query
  defp filter_by_location(query, location), do:
    where(query, [p], ilike(p.location, ^"%#{location}%"))

  defp filter_by_radius(query, nil, nil, _), do: query
  defp filter_by_radius(query, lat, lng, radius_km) do
    radius_meters = (radius_km || 5) * 1000

    from p in query,
      where: fragment(
        "ST_DWithin(?, ST_SetSRID(ST_MakePoint(?, ?), 4326), ?)",
        p.coordinates, ^lng, ^lat, ^radius_meters
      )
  end

  defp filter_by_active(query, nil), do:
    where(query, [p], p.is_active == true)

  defp filter_by_active(query, active), do:
    where(query, [p], p.is_active == ^active)
end
