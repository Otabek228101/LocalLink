defmodule LocallinkApiWeb.PostController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Posts
  alias LocallinkApi.Guardian

  require Logger

  action_fallback LocallinkApiWeb.FallbackController

  def index(conn, params) do
    filters = %{
      category: params["category"],
      location: params["location"],
      active: params["active"],
      lat: parse_float(params["lat"]),
      lng: parse_float(params["lng"]),
      radius_km: parse_float(params["radius_km"])
    }

    posts = Posts.list_posts(filters)

    conn |> json(%{posts: Enum.map(posts, &format_post/1)})
  end

  def show(conn, %{"id" => id}) do
    case Posts.get_post(id) do
      {:ok, post} -> conn |> json(%{post: format_post(post)})
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  def create(conn, %{"post" => post_params}) do
    user = Guardian.Plug.current_resource(conn)

    case Posts.create_post(user, post_params) do
      {:ok, post} ->
        post = LocallinkApi.Repo.preload(post, :user)
        conn
        |> put_status(:created)
        |> json(%{
          message: "Post created successfully",
          post: format_post(post)
        })

      {:error, changeset} -> {:error, changeset}
    end
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    user = Guardian.Plug.current_resource(conn)

    case Posts.get_post(id) do
      {:ok, post} ->
        if post.user_id == user.id do
          case Posts.update_post(post, post_params) do
            {:ok, updated_post} ->
              updated_post = LocallinkApi.Repo.preload(updated_post, :user)
              conn |> json(%{message: "Post updated", post: format_post(updated_post)})
            {:error, changeset} -> {:error, changeset}
          end
        else
          {:error, :forbidden}
        end

      {:error, :not_found} -> {:error, :not_found}
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)

    case Posts.get_post(id) do
      {:ok, post} ->
        if post.user_id == user.id do
          case Posts.delete_post(post) do
            {:ok, _} -> conn |> json(%{message: "Post deleted"})
            {:error, _} -> {:error, "Failed to delete post"}
          end
        else
          {:error, :forbidden}
        end

      {:error, :not_found} -> {:error, :not_found}
    end
  end

  def my_posts(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    posts = Posts.get_user_posts(user.id)
    conn |> json(%{posts: Enum.map(posts, &format_post/1)})
  end

  def hot_zones(conn, _params) do
    zones = Posts.hot_zones()
    conn |> json(%{hot_zones: zones})
  end

  defp parse_float(nil), do: nil
  defp parse_float(value) do
    case Float.parse(value) do
      {f, _} -> f
      _ -> nil
    end
  end

  defp format_post(post) do
    %{
      id: post.id,
      title: post.title,
      description: post.description,
      category: post.category,
      post_type: post.post_type,
      location: post.location,
      urgency: post.urgency,
      price: post.price,
      currency: post.currency,
      skills_required: post.skills_required,
      duration_estimate: post.duration_estimate,
      max_distance_km: post.max_distance_km,
      is_active: post.is_active,
      expires_at: post.expires_at,
      images: post.images,
      contact_preference: post.contact_preference,
      coordinates: post.coordinates,
      inserted_at: post.inserted_at,
      updated_at: post.updated_at,
      user: %{
        id: post.user.id,
        first_name: post.user.first_name,
        last_name: post.user.last_name,
        rating: post.user.rating,
        total_jobs_completed: post.user.total_jobs_completed
      }
    }
  end
end
