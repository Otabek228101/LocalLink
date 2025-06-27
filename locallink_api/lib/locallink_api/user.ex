defmodule LocallinkApi.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias LocallinkApi.Post

  schema "users" do
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :first_name, :string
    field :last_name, :string
    field :phone, :string
    field :location, :string
    field :skills, :string
    field :availability, :string
    field :is_verified, :boolean, default: false
    field :profile_image_url, :string
    field :rating, :decimal
    field :total_jobs_completed, :integer, default: 0

    has_many :posts, Post

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :first_name, :last_name, :phone, :location, :skills, :availability, :profile_image_url])
    |> validate_required([:email, :password, :first_name, :last_name])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:password, min: 6, max: 100)
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  def registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> validate_required([:password])
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password_hash: Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset

  def valid_password?(user, password) do
    Bcrypt.verify_pass(password, user.password_hash)
  end
end
