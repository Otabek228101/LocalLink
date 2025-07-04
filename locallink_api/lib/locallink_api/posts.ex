defmodule LocallinkApi.Posts do
  @moduledoc """
  The Posts context.
  """

  import Ecto.Query, warn: false
  alias LocallinkApi.Repo
  alias LocallinkApi.Post
  alias LocallinkApi.User
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
    result = %Post{}
    |> Post.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()

    case result do
      {:ok, post} ->
        # Отправить уведомления пользователям рядом
        Task.start(fn ->
          LocallinkApi.Notifications.notify_nearby_users(post.id)
        end)

        {:ok, post}

      error -> error
    end
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
      AND coordinates IS NOT NULL
    GROUP BY ST_SnapToGrid(coordinates, 0.01, 0.01)
    HAVING COUNT(*) > 2
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

  @doc """
  Присоединиться к событию.
  """
  def join_event(post_id, user_id) do
    case get_post(post_id) do
      {:ok, post} ->
        cond do
          post.category != "event" ->
            {:error, "Post is not an event"}

          user_id == post.user_id ->
            {:error, "Cannot join your own event"}

          user_id in (post.participants || []) ->
            {:error, "Already joined this event"}

          (post.current_participants || 0) >= (post.max_participants || 0) ->
            {:error, "Event is full"}

          event_expired?(post) ->
            {:error, "Event has already passed"}

          true ->
            add_participant(post, user_id)
        end

      error -> error
    end
  end

  @doc """
  Покинуть событие.
  """
  def leave_event(post_id, user_id) do
    case get_post(post_id) do
      {:ok, post} ->
        cond do
          post.category != "event" ->
            {:error, "Post is not an event"}

          user_id == post.user_id ->
            {:error, "Cannot leave your own event"}

          user_id not in (post.participants || []) ->
            {:error, "You are not a participant"}

          true ->
            remove_participant(post, user_id)
        end

      error -> error
    end
  end

  @doc """
  Получить список участников события с их профилями.
  """
  def get_event_participants(post_id) do
    case get_post(post_id) do
      {:ok, post} when post.category == "event" ->
        participant_ids = post.participants || []

        participants = User
        |> where([u], u.id in ^participant_ids)
        |> select([u], %{
          id: u.id,
          first_name: u.first_name,
          last_name: u.last_name,
          rating: u.rating,
          profile_image_url: u.profile_image_url,
          total_jobs_completed: u.total_jobs_completed
        })
        |> Repo.all()

        {:ok, participants}

      {:ok, _post} ->
        {:error, "Post is not an event"}

      error -> error
    end
  end

  @doc """
  Получить статистику события.
  """
  def get_event_stats(post_id) do
    case get_post(post_id) do
      {:ok, post} when post.category == "event" ->
        stats = %{
          current_participants: post.current_participants || 0,
          max_participants: post.max_participants || 0,
          available_spots: (post.max_participants || 0) - (post.current_participants || 0),
          is_full: (post.current_participants || 0) >= (post.max_participants || 0),
          event_date: post.event_date,
          is_expired: event_expired?(post),
          organizer: %{
            id: post.user.id,
            name: "#{post.user.first_name} #{post.user.last_name}",
            rating: post.user.rating
          }
        }

        {:ok, stats}

      {:ok, _post} ->
        {:error, "Post is not an event"}

      error -> error
    end
  end

  @doc """
  Получить список событий с доступными местами.
  """
  def list_available_events(filters \\ %{}) do
    now = NaiveDateTime.utc_now()

    Post
    |> where([p], p.category == "event")
    |> where([p], p.is_active == true)
    |> where([p], p.event_date > ^now)
    |> where([p], fragment("(? < ? OR ? IS NULL)", p.current_participants, p.max_participants, p.max_participants))
    |> filter_by_location(filters[:location])
    |> filter_by_radius(filters[:lat], filters[:lng], filters[:radius_km])
    |> order_by([p], asc: p.event_date)
    |> limit(50)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  @doc """
  Получить события пользователя (созданные и где участвует).
  """
  def get_user_events(user_id) do
    created_events = Post
    |> where([p], p.user_id == ^user_id and p.category == "event")
    |> order_by(desc: :event_date)
    |> Repo.all()
    |> Repo.preload(:user)

    # События где пользователь участник
    participating_events = Post
    |> where([p], p.category == "event")
    |> where([p], fragment("? = ANY(?)", ^user_id, p.participants))
    |> order_by(desc: :event_date)
    |> Repo.all()
    |> Repo.preload(:user)

    %{
      created: created_events,
      participating: participating_events
    }
  end

  # ===============================
  # ПРИВАТНЫЕ ФУНКЦИИ
  # ===============================

  defp add_participant(post, user_id) do
    new_participants = [user_id | (post.participants || [])]
    new_count = length(new_participants)

    post
    |> Post.changeset(%{
      participants: new_participants,
      current_participants: new_count
    })
    |> Repo.update()
  end

  defp remove_participant(post, user_id) do
    new_participants = List.delete(post.participants || [], user_id)
    new_count = length(new_participants)

    post
    |> Post.changeset(%{
      participants: new_participants,
      current_participants: new_count
    })
    |> Repo.update()
  end

  defp event_expired?(post) do
    case post.event_date do
      nil -> false
      event_date ->
        NaiveDateTime.compare(event_date, NaiveDateTime.utc_now()) != :gt
    end
  end

  # Функции фильтрации (только один раз!)
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
