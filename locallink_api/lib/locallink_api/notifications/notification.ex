defmodule LocallinkApi.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "notifications" do
    field :title, :string
    field :message, :string
    field :notification_type, :string
    field :distance_meters, :integer
    field :priority, :string, default: "normal"
    field :status, :string, default: "sent"
    field :read_at, :naive_datetime
    field :clicked_at, :naive_datetime
    field :delivery_method, :string, default: "websocket"
    field :delivered_at, :naive_datetime

    belongs_to :user, LocallinkApi.User
    belongs_to :post, LocallinkApi.Post
    timestamps()
  end

  @valid_types ["job_nearby", "event_nearby", "task_nearby", "help_nearby", "emergency_nearby"]
  @valid_priorities ["low", "normal", "high", "urgent"]
  @valid_statuses ["sent", "delivered", "read", "clicked"]

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [
      :title, :message, :notification_type, :distance_meters, :priority,
      :status, :delivery_method, :user_id, :post_id
    ])
    |> validate_required([:title, :message, :notification_type, :user_id, :post_id])
    |> validate_inclusion(:notification_type, @valid_types)
    |> validate_inclusion(:priority, @valid_priorities)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_number(:distance_meters, greater_than: 0)
  end
end
