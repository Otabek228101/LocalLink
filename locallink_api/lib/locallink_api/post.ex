defmodule LocallinkApi.Post do
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  use Ecto.Schema
  import Ecto.Changeset
  alias LocallinkApi.User

  schema "posts" do
    field :title, :string
    field :description, :string
    field :category, :string
    field :post_type, :string
    field :location, :string
    field :urgency, :string
    field :price, :decimal
    field :currency, :string, default: "UZS"
    field :skills_required, :string
    field :duration_estimate, :string
    field :max_distance_km, :integer, default: 10
    field :is_active, :boolean, default: true
    field :expires_at, :naive_datetime
    field :images, :string
    field :contact_preference, :string, default: "app"
    field :coordinates, Geo.PostGIS.Geometry
    field :max_participants, :integer
    field :current_participants, :integer, default: 0
    field :participants, {:array, :binary_id}, default: []
    field :event_date, :naive_datetime

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [
      :title, :description, :category, :post_type, :location, :urgency,
      :price, :currency, :skills_required, :duration_estimate,
      :max_distance_km, :is_active, :expires_at, :images,
      :contact_preference, :coordinates,
      :max_participants, :current_participants, :participants, :event_date
    ])
    |> validate_required([:title, :description, :category, :post_type, :location])
    |> validate_inclusion(:category, ["job", "task", "event", "help_needed", "social"])
    |> validate_inclusion(:post_type, ["offer", "seeking", "event"])
    |> validate_inclusion(:urgency, ["now", "today", "tomorrow", "this_week", "flexible"])
    |> validate_inclusion(:contact_preference, ["app", "phone", "both"])
    |> validate_number(:price, greater_than: 0)
    |> validate_number(:max_distance_km, greater_than: 0)
    |> validate_length(:title, min: 3, max: 200)
    |> validate_length(:description, min: 10, max: 1000)
    |> validate_length(:location, min: 2, max: 100)
    |> validate_coordinates()
    |> validate_event_fields()
  end

  # ✅ Проверка координат
  defp validate_coordinates(changeset) do
    case get_field(changeset, :coordinates) do
      %Geo.Point{} -> changeset
      nil -> changeset  # координаты не обязательны
      _ -> add_error(changeset, :coordinates, "must be a valid Geo.Point")
    end
  end

  # ✅ Проверка полей события, если это пост типа "event"
  defp validate_event_fields(changeset) do
    post_type = get_field(changeset, :post_type)

    if post_type == "event" do
      changeset
      |> validate_required([:event_date, :max_participants])
      |> validate_number(:max_participants, greater_than: 0)
    else
      changeset
    end
  end
end
