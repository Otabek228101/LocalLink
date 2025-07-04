defmodule LocallinkApiWeb.NotificationController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Notifications
  alias LocallinkApi.Guardian

  action_fallback LocallinkApiWeb.FallbackController

  @doc """
  GET /api/v1/notifications/preferences
  Получить настройки уведомлений.
  """
  def get_preferences(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    case Notifications.get_or_create_preferences(user.id) do
      {:ok, preferences} ->
        json(conn, %{preferences: format_preferences(preferences)})

      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  PUT /api/v1/notifications/preferences
  Обновить настройки уведомлений.
  """
  def update_preferences(conn, %{"preferences" => preferences_params}) do
    user = Guardian.Plug.current_resource(conn)

    case Notifications.update_preferences(user.id, preferences_params) do
      {:ok, preferences} ->
        json(conn, %{
          message: "Preferences updated successfully",
          preferences: format_preferences(preferences)
        })

      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  POST /api/v1/notifications/location
  Обновить текущее местоположение.
  """
  def update_location(conn, %{"lat" => lat, "lng" => lng}) do
    user = Guardian.Plug.current_resource(conn)

    case Notifications.update_location(user.id, lat, lng) do
      {:ok, _preferences} ->
        json(conn, %{message: "Location updated successfully"})

      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  GET /api/v1/notifications
  Получить уведомления пользователя.
  """
  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    limit = String.to_integer(params["limit"] || "50")

    notifications =
      if params["unread_only"] == "true" do
        Notifications.get_unread_notifications(user.id, limit)
      else
        Notifications.get_user_notifications(user.id, limit)
      end

    json(conn, %{
      notifications: Enum.map(notifications, &format_notification/1)
    })
  end

  @doc """
  PUT /api/v1/notifications/:id/read
  Отметить уведомление как прочитанное.
  """
  def mark_as_read(conn, %{"id" => notification_id}) do
    user = Guardian.Plug.current_resource(conn)

    case Notifications.mark_as_read(notification_id, user.id) do
      {1, _} -> json(conn, %{message: "Notification marked as read"})
      {0, _} -> {:error, :not_found}
    end
  end

  @doc """
  PUT /api/v1/notifications/:id/clicked
  Отметить уведомление как кликнутое.
  """
  def mark_as_clicked(conn, %{"id" => notification_id}) do
    user = Guardian.Plug.current_resource(conn)

    case Notifications.mark_as_clicked(notification_id, user.id) do
      {1, _} -> json(conn, %{message: "Notification marked as clicked"})
      {0, _} -> {:error, :not_found}
    end
  end

  # ===============================
  # HELPER FUNCTIONS
  # ===============================

  defp format_preferences(preferences) do
    %{
      notification_radius_km: preferences.notification_radius_km,
      notify_jobs: preferences.notify_jobs,
      notify_tasks: preferences.notify_tasks,
      notify_events: preferences.notify_events,
      notify_help: preferences.notify_help,
      quiet_hours_start: preferences.quiet_hours_start,
      quiet_hours_end: preferences.quiet_hours_end,
      weekend_notifications: preferences.weekend_notifications,
      min_price: preferences.min_price,
      max_price: preferences.max_price,
      skills_filter: preferences.skills_filter,
      is_active: preferences.is_active,
      last_location_update: preferences.last_location_update
    }
  end

  defp format_notification(notification) do
    %{
      id: notification.id,
      title: notification.title,
      message: notification.message,
      type: notification.notification_type,
      priority: notification.priority,
      distance_meters: notification.distance_meters,
      status: notification.status,
      read_at: notification.read_at,
      clicked_at: notification.clicked_at,
      inserted_at: notification.inserted_at,
      post: %{
        id: notification.post.id,
        title: notification.post.title,
        category: notification.post.category,
        price: notification.post.price,
        currency: notification.post.currency
      }
    }
  end
end
