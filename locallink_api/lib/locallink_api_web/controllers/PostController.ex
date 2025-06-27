defmodule LocallinkApiWeb.PostController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Posts
  alias LocallinkApi.Guardian

  def index(conn, params) do
    filters = %{
      category: params["category"],
      location: params["location"],
      active: params["active"]
    }

    posts = Posts.list_posts(filters)

    conn
    |> json(%{
      posts: Enum.map(posts, &format_post/1)
    })
  end

  def show(conn, %{"id" => id}) do
    case Posts.get_post(id) do
      {:ok, post} ->
        conn
        |> json(%{post: format_post(post)})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Post not found"})
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

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(changeset)})
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

              conn
              |> json(%{
                message: "Post updated successfully",
                post: format_post(updated_post)
              })

            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{errors: translate_errors(changeset)})
          end
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "You can only update your own posts"})
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Post not found"})
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)

    case Posts.get_post(id) do
      {:ok, post} ->
        if post.user_id == user.id do
          case Posts.delete_post(post) do
            {:ok, _deleted_post} ->
              conn
              |> json(%{message: "Post deleted successfully"})

            {:error, _changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{error: "Failed to delete post"})
          end
        else
          conn
          |> put_status(:forbidden)
          |> json(%{error: "You can only delete your own posts"})
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Post not found"})
    end
  end

  def my_posts(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    posts = Posts.get_user_posts(user.id)

    conn
    |> json(%{
      posts: Enum.map(posts, &format_post/1)
    })
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

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
