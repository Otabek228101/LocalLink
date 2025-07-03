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
      :contact_preference, :coordinates
    ])
    |> validate_required([:title, :description, :category, :post_type, :location])
    |> validate_inclusion(:category, ["job", "task", "event", "help_needed", "social"])
    |> validate_inclusion(:post_type, ["offer", "seeking"])
    |> validate_inclusion(:urgency, ["now", "today", "tomorrow", "this_week", "flexible"])
    |> validate_inclusion(:contact_preference, ["app", "phone", "both"])
    |> validate_number(:price, greater_than: 0)
    |> validate_number(:max_distance_km, greater_than: 0)
    |> validate_length(:title, min: 3, max: 200)
    |> validate_length(:description, min: 10, max: 1000)
    |> validate_length(:location, min: 2, max: 100)
    |> validate_change(:coordinates, fn :coordinates, value ->
      case value do
        %Geo.Point{} -> []
        _ -> [coordinates: "Invalid coordinates format"]
      end
    end)
  end
end
