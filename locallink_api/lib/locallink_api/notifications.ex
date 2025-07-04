defmodule LocallinkApi.Notifications do
  @moduledoc """
  Контекст для управления уведомлениями пользователей.
  """

  import Ecto.Query, warn: false
  alias LocallinkApi.Repo
  alias LocallinkApi.Notifications.{NotificationPreference, Notification}
  alias LocallinkApi.{User, Post}

  # ===============================
  # НАСТРОЙКИ УВЕДОМЛЕНИЙ
  # ===============================

  @doc """
  Получить или создать настройки уведомлений для пользователя.
  """
  def get_or_create_preferences(user_id) do
    case Repo.get_by(NotificationPreference, user_id: user_id) do
      nil ->
        %NotificationPreference{user_id: user_id}
        |> NotificationPreference.changeset(%{})
        |> Repo.insert()

      preferences -> {:ok, preferences}
    end
  end

  @doc """
  Обновить настройки уведомлений.
  """
  def update_preferences(user_id, attrs) do
    case get_or_create_preferences(user_id) do
      {:ok, preferences} ->
        preferences
        |> NotificationPreference.changeset(attrs)
        |> Repo.update()

      error -> error
    end
  end

  @doc """
  Обновить текущее местоположение пользователя.
  """
  def update_location(user_id, lat, lng) do
    location = %Geo.Point{coordinates: {lng, lat}, srid: 4326}

    update_preferences(user_id, %{
      current_location: location,
      last_location_update: NaiveDateTime.utc_now()
    })
  end

  # ===============================
  # ОТПРАВКА УВЕДОМЛЕНИЙ
  # ===============================

  @doc """
  Проверить новые посты и отправить уведомления.
  Вызывается при создании нового поста.
  """
  def notify_nearby_users(post_id) do
    case Repo.get(Post, post_id) |> Repo.preload(:user) do
      nil -> {:error, :post_not_found}

      post ->
        # Найти пользователей рядом с постом
        nearby_users = find_users_nearby(post)

        # Отправить уведомления каждому
        Enum.each(nearby_users, fn {user, distance, preferences} ->
          send_notification(user, post, distance, preferences)
        end)

        {:ok, length(nearby_users)}
    end
  end

  @doc """
  Отправить уведомление конкретному пользователю.
  """
  def send_notification(user, post, distance_meters, preferences) do
    # Проверить можно ли отправлять уведомление
    if should_notify?(user, post, preferences) do
      notification_attrs = %{
        user_id: user.id,
        post_id: post.id,
        title: create_notification_title(post),
        message: create_notification_message(post, distance_meters),
        notification_type: get_notification_type(post.category),
        distance_meters: distance_meters,
        priority: get_notification_priority(post),
        delivered_at: NaiveDateTime.utc_now()
      }

      case create_notification(notification_attrs) do
        {:ok, notification} ->
          # Отправить через WebSocket
          broadcast_notification(user.id, notification)
          {:ok, notification}

        error -> error
      end
    else
      {:ok, :skipped}
    end
  end

  # ===============================
  # УВЕДОМЛЕНИЯ CRUD
  # ===============================

  @doc """
  Создать уведомление.
  """
  def create_notification(attrs) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Отметить уведомление как прочитанное.
  """
  def mark_as_read(notification_id, user_id) do
    Notification
    |> where([n], n.id == ^notification_id and n.user_id == ^user_id)
    |> Repo.update_all(set: [
      status: "read",
      read_at: NaiveDateTime.utc_now(),
      updated_at: NaiveDateTime.utc_now()
    ])
  end

  @doc """
  Отметить уведомление как кликнутое.
  """
  def mark_as_clicked(notification_id, user_id) do
    Notification
    |> where([n], n.id == ^notification_id and n.user_id == ^user_id)
    |> Repo.update_all(set: [
      status: "clicked",
      clicked_at: NaiveDateTime.utc_now(),
      updated_at: NaiveDateTime.utc_now()
    ])
  end

  @doc """
  Получить непрочитанные уведомления пользователя.
  """
  def get_unread_notifications(user_id, limit \\ 50) do
    Notification
    |> where([n], n.user_id == ^user_id and n.status in ["sent", "delivered"])
    |> order_by(desc: :inserted_at)
    |> limit(^limit)
    |> preload(:post)
    |> Repo.all()
  end

  @doc """
  Получить все уведомления пользователя.
  """
  def get_user_notifications(user_id, limit \\ 100) do
    Notification
    |> where([n], n.user_id == ^user_id)
    |> order_by(desc: :inserted_at)
    |> limit(^limit)
    |> preload(:post)
    |> Repo.all()
  end

  # ===============================
  # ПРИВАТНЫЕ ФУНКЦИИ
  # ===============================

  # Найти пользователей рядом с постом
  defp find_users_nearby(post) do
    if post.coordinates do
      query = """
      SELECT
        u.id, u.first_name, u.last_name, u.email,
        np.notification_radius_km, np.notify_jobs, np.notify_tasks,
        np.notify_events, np.notify_help, np.is_active,
        ST_Distance(np.current_location, $1) as distance_meters
      FROM users u
      JOIN notification_preferences np ON u.id = np.user_id
      WHERE np.is_active = true
        AND np.current_location IS NOT NULL
        AND u.id != $2
        AND ST_DWithin(np.current_location, $1, np.notification_radius_km * 1000)
      ORDER BY distance_meters ASC
      LIMIT 100
      """

      case Ecto.Adapters.SQL.query(Repo, query, [post.coordinates, post.user_id]) do
        {:ok, %{rows: rows}} ->
          Enum.map(rows, fn [user_id, first_name, last_name, email, radius, notify_jobs, notify_tasks, notify_events, notify_help, is_active, distance] ->
            user = %User{
              id: user_id,
              first_name: first_name,
              last_name: last_name,
              email: email
            }

            preferences = %{
              notification_radius_km: radius,
              notify_jobs: notify_jobs,
              notify_tasks: notify_tasks,
              notify_events: notify_events,
              notify_help: notify_help,
              is_active: is_active
            }

            {user, round(distance), preferences}
          end)

        _error -> []
      end
    else
      []
    end
  end

  # Проверить нужно ли отправлять уведомление
  defp should_notify?(user, post, preferences) do
    cond do
      !preferences.is_active -> false
      post.category == "job" && !preferences.notify_jobs -> false
      post.category == "task" && !preferences.notify_tasks -> false
      post.category == "event" && !preferences.notify_events -> false
      post.category == "help_needed" && !preferences.notify_help -> false
      is_quiet_hours?() -> false
      true -> true
    end
  end

  # Проверить тихие часы
  defp is_quiet_hours? do
    # Простая проверка - с 22:00 до 8:00
    current_hour = Time.utc_now().hour
    current_hour >= 22 || current_hour <= 8
  end

  # Создать заголовок уведомления
  defp create_notification_title(post) do
    case post.category do
      "job" -> "💼 Работа рядом с вами"
      "task" -> "✅ Задача поблизости"
      "event" -> "🎉 Событие рядом"
      "help_needed" -> "🆘 Нужна помощь рядом"
      _ -> "📍 Объявление поблизости"
    end
  end

  # Создать текст уведомления
  defp create_notification_message(post, distance_meters) do
    distance_text =
      if distance_meters < 1000 do
        "#{distance_meters}м"
      else
        "#{Float.round(distance_meters / 1000, 1)}км"
      end

    price_text = if post.price, do: ", #{post.price} #{post.currency}", else: ""

    "#{post.title}#{price_text}, #{distance_text} от вас"
  end

  # Определить тип уведомления
  defp get_notification_type(category) do
    case category do
      "job" -> "job_nearby"
      "task" -> "task_nearby"
      "event" -> "event_nearby"
      "help_needed" -> "help_nearby"
      _ -> "post_nearby"
    end
  end

  # Определить приоритет уведомления
  defp get_notification_priority(post) do
    case post.urgency do
      "now" -> "urgent"
      "today" -> "high"
      "tomorrow" -> "normal"
      _ -> "normal"
    end
  end

  # Отправить уведомление через WebSocket
  defp broadcast_notification(user_id, notification) do
    Phoenix.PubSub.broadcast(
      LocallinkApi.PubSub,
      "user:#{user_id}",
      {:new_notification, %{
        id: notification.id,
        title: notification.title,
        message: notification.message,
        type: notification.notification_type,
        priority: notification.priority,
        distance: notification.distance_meters,
        post_id: notification.post_id,
        inserted_at: notification.inserted_at
      }}
    )
  end
end
