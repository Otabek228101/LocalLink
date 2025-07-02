defmodule LocallinkApiWeb.PostController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Posts
  alias LocallinkApi.Guardian

  require Logger

  # Используем fallback controller для обработки ошибок
  action_fallback LocallinkApiWeb.FallbackController

  def index(conn, params) do
    Logger.info("Posts index request with params: #{inspect(params)}")

    filters = %{
      category: params["category"],
      location: params["location"],
      active: params["active"]
    }

    posts = Posts.list_posts(filters)
    Logger.info("Found #{length(posts)} posts")

    conn
    |> json(%{
      posts: Enum.map(posts, &format_post/1)
    })
  end

  def show(conn, %{"id" => id}) do
    Logger.info("Post show request for ID: #{id}")

    case Posts.get_post(id) do
      {:ok, post} ->
        conn
        |> json(%{post: format_post(post)})

      {:error, :not_found} ->
        Logger.warn("Post not found: #{id}")
        {:error, :not_found}
    end
  end

  def create(conn, %{"post" => post_params}) do
    user = Guardian.Plug.current_resource(conn)
    Logger.info("Creating post for user: #{user.id}")
    Logger.debug("Post params: #{inspect(post_params)}")

    case Posts.create_post(user, post_params) do
      {:ok, post} ->
        post = LocallinkApi.Repo.preload(post, :user)
        Logger.info("Post created successfully: #{post.id}")

        conn
        |> put_status(:created)
        |> json(%{
          message: "Post created successfully",
          post: format_post(post)
        })

      {:error, changeset} ->
        Logger.warn("Post creation failed: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    user = Guardian.Plug.current_resource(conn)
    Logger.info("Update post request for ID: #{id} by user: #{user.id}")

    case Posts.get_post(id) do
      {:ok, post} ->
        if post.user_id == user.id do
          case Posts.update_post(post, post_params) do
            {:ok, updated_post} ->
              updated_post = LocallinkApi.Repo.preload(updated_post, :user)
              Logger.info("Post updated successfully: #{id}")

              conn
              |> json(%{
                message: "Post updated successfully",
                post: format_post(updated_post)
              })

            {:error, changeset} ->
              Logger.warn("Post update failed: #{inspect(changeset.errors)}")
              {:error, changeset}
          end
        else
          Logger.warn("Unauthorized update attempt for post: #{id}")
          {:error, :forbidden}
        end

      {:error, :not_found} ->
        Logger.warn("Post not found for update: #{id}")
        {:error, :not_found}
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)
    Logger.info("Delete post request for ID: #{id} by user: #{user.id}")

    case Posts.get_post(id) do
      {:ok, post} ->
        if post.user_id == user.id do
          case Posts.delete_post(post) do
            {:ok, _deleted_post} ->
              Logger.info("Post deleted successfully: #{id}")

              conn
              |> json(%{message: "Post deleted successfully"})

            {:error, _changeset} ->
              Logger.error("Failed to delete post: #{id}")
              {:error, "Failed to delete post"}
          end
        else
          Logger.warn("Unauthorized delete attempt for post: #{id}")
          {:error, :forbidden}
        end

      {:error, :not_found} ->
        Logger.warn("Post not found for deletion: #{id}")
        {:error, :not_found}
    end
  end

  def my_posts(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    Logger.info("My posts request for user: #{user.id}")

    posts = Posts.get_user_posts(user.id)
    Logger.info("Found #{length(posts)} posts for user: #{user.id}")

    conn
    |> json(%{
      posts: Enum.map(posts, &format_post/1)
    })
  end

  # Обработка неправильного формата запроса для create
  def create(conn, _params) do
    Logger.warn("Invalid create post parameters")
    {:error, "Invalid request format. Expected: {\"post\": {...}}"}
  end

  # Обработка неправильного формата запроса для update
  def update(conn, _params) do
    Logger.warn("Invalid update post parameters")
    {:error, "Invalid request format. Expected: {\"post\": {...}}"}
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
end
