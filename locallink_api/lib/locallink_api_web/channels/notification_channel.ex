defmodule LocallinkApiWeb.NotificationChannel do
  use Phoenix.Channel

  alias LocallinkApi.Notifications

  def join("notifications:" <> user_id, _params, socket) do
    current_user = socket.assigns.current_user

    if current_user.id == user_id do
      # Подписываемся на уведомления этого пользователя
      Phoenix.PubSub.subscribe(LocallinkApi.PubSub, "user:#{user_id}")

      {:ok, assign(socket, :user_id, user_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Обработка новых уведомлений
  def handle_info({:new_notification, notification}, socket) do
    push(socket, "new_notification", notification)
    {:noreply, socket}
  end

  # Обновление местоположения от клиента
  def handle_in("update_location", %{"lat" => lat, "lng" => lng}, socket) do
    user_id = socket.assigns.user_id

    case Notifications.update_location(user_id, lat, lng) do
      {:ok, _} ->
        {:reply, {:ok, %{message: "Location updated"}}, socket}

      {:error, _reason} ->
        {:reply, {:error, %{message: "Failed to update location"}}, socket}
    end
  end

  # Отметить уведомление как прочитанное
  def handle_in("mark_read", %{"notification_id" => notification_id}, socket) do
    user_id = socket.assigns.user_id
    Notifications.mark_as_read(notification_id, user_id)
    {:noreply, socket}
  end
end
