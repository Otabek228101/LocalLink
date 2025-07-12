# lib/locallink_api/notifications/notification_preference.ex

defmodule LocallinkApi.Notifications.NotificationPreference do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "notification_preferences" do
    # Геолокация
    field :current_location, Geo.PostGIS.Geometry
    field :home_location, Geo.PostGIS.Geometry
    field :work_location, Geo.PostGIS.Geometry
    field :notification_radius_km, :float, default: 2.0

    # Типы уведомлений
    field :notify_jobs, :boolean, default: true
    field :notify_tasks, :boolean, default: true
    field :notify_events, :boolean, default: true
    field :notify_help, :boolean, default: true

    # Временные рамки
    field :quiet_hours_start, :time
    field :quiet_hours_end, :time
    field :weekend_notifications, :boolean, default: true

    # Фильтры
    field :min_price, :decimal
    field :max_price, :decimal
    field :skills_filter, {:array, :string}, default: []

    # Статус
    field :is_active, :boolean, default: true
    field :last_location_update, :naive_datetime

    belongs_to :user, LocallinkApi.User
    timestamps()
  end

  @doc """
  Применяет входящие атрибуты и обновляет `:last_location_update`,
  обрезая микросекунды.
  """
  def changeset(preference, attrs) do
    preference
    |> cast(attrs, [
      :current_location, :home_location, :work_location, :notification_radius_km,
      :notify_jobs, :notify_tasks, :notify_events, :notify_help,
      :quiet_hours_start, :quiet_hours_end, :weekend_notifications,
      :min_price, :max_price, :skills_filter, :is_active
    ])
    |> validate_number(:notification_radius_km, greater_than: 0, less_than: 50)
    |> validate_number(:min_price, greater_than: 0)
    |> validate_number(:max_price, greater_than: 0)
    |> validate_price_range()
    |> put_change(
      :last_location_update,
      NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    )
  end

  defp validate_price_range(changeset) do
    min_price = get_change(changeset, :min_price)
    max_price = get_change(changeset, :max_price)

    if min_price && max_price && Decimal.compare(min_price, max_price) == :gt do
      add_error(changeset, :max_price, "must be greater than min_price")
    else
      changeset
    end
  end
end
