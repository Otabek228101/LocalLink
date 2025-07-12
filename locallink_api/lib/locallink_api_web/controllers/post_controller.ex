defmodule LocallinkApiWeb.PostController do
  use LocallinkApiWeb, :controller

  alias LocallinkApi.Posts
  alias LocallinkApi.Guardian
  alias LocallinkApi.Repo

  import NaiveDateTime, only: [to_date: 1, to_time: 1]

  action_fallback LocallinkApiWeb.FallbackController

  @doc "GET /api/v1/posts"
  def index(conn, params) do
    posts = Posts.list_posts(params)

    conn
    |> json(%{posts: Enum.map(posts, &format_post/1)})
  end

  @doc "GET /api/v1/posts/:id"
  def show(conn, %{"id" => id}) do
    with {:ok, post} <- Posts.get_post(id) do
      conn
      |> json(%{post: format_post(post)})
    end
  end

  @doc "POST /api/v1/posts"
  def create(conn, %{"post" => post_params}) do
    user = Guardian.Plug.current_resource(conn)

    with {:ok, post} <- Posts.create_post(user, post_params),
         post      <- Repo.preload(post, :user) do
      conn
      |> put_status(:created)
      |> json(%{message: "Post created successfully", post: format_post(post)})
    end
  end

  @doc "PUT /api/v1/posts/:id"
  def update(conn, %{"id" => id, "post" => attrs}) do
    with {:ok, post}    <- Posts.get_post(id),
         {:ok, updated} <- Posts.update_post(post, attrs) do
      conn
      |> json(%{message: "Post updated", post: format_post(updated)})
    end
  end

  @doc "DELETE /api/v1/posts/:id"
  def delete(conn, %{"id" => id}) do
    with {:ok, post} <- Posts.get_post(id),
         {:ok, _}    <- Posts.delete_post(post) do
      conn
      |> json(%{message: "Post deleted"})
    end
  end

  # Вспомогательная функция для базового JSON
  defp format_post(post) do
    post
    |> Map.take([
      :id,
      :title,
      :description,
      :category,
      :post_type,
      :location,
      :urgency,
      :price,
      :currency,
      :max_distance_km,
      :is_active,
      :inserted_at
    ])
    |> Map.merge(%{
      user: %{
        id:                   post.user.id,
        first_name:           post.user.first_name,
        last_name:            post.user.last_name,
        rating:               post.user.rating,
        total_jobs_completed: post.user.total_jobs_completed
      }
    })
    |> maybe_merge_event_fields(post)
  end
  defp maybe_merge_event_fields(map, %{post_type: "event", event_date: dt} = post) do
    %{
      event_date: to_date(dt),
      event_time: to_time(dt),
      capacity:   post.max_participants,
      notes:      Map.get(post, :notes, nil)
    }
    |> Map.merge(map)
  end
  defp maybe_merge_event_fields(map, _), do: map
end
