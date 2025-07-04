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
  @doc """
  POST /api/v1/posts/:id/join
  Присоединиться к событию.
  """
  def join_event(conn, %{"id" => post_id}) do
    user = Guardian.Plug.current_resource(conn)

    case Posts.join_event(post_id, user.id) do
      {:ok, post} ->
        Logger.info("User #{user.id} joined event #{post_id}")

        conn
        |> json(%{
          message: "Successfully joined the event!",
          event: %{
            id: post.id,
            title: post.title,
            current_participants: post.current_participants,
            max_participants: post.max_participants,
            available_spots: post.max_participants - post.current_participants
          }
        })

      {:error, reason} ->
        Logger.warn("Failed to join event #{post_id}: #{reason}")

        conn
        |> put_status(:bad_request)
        |> json(%{
          error: reason,
          message: get_join_error_message(reason)
        })
    end
  end

  @doc """
  DELETE /api/v1/posts/:id/leave
  Покинуть событие.
  """
  def leave_event(conn, %{"id" => post_id}) do
    user = Guardian.Plug.current_resource(conn)

    case Posts.leave_event(post_id, user.id) do
      {:ok, post} ->
        Logger.info("User #{user.id} left event #{post_id}")

        conn
        |> json(%{
          message: "Successfully left the event",
          event: %{
            id: post.id,
            title: post.title,
            current_participants: post.current_participants,
            max_participants: post.max_participants,
            available_spots: post.max_participants - post.current_participants
          }
        })

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          error: reason,
          message: get_leave_error_message(reason)
        })
    end
  end

  @doc """
  GET /api/v1/posts/:id/participants
  Получить список участников события.
  """
  def event_participants(conn, %{"id" => post_id}) do
    case Posts.get_event_participants(post_id) do
      {:ok, participants} ->
        conn
        |> json(%{
          participants: participants,
          count: length(participants)
        })

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  @doc """
  GET /api/v1/posts/:id/stats
  Получить статистику события.
  """
  def event_stats(conn, %{"id" => post_id}) do
    case Posts.get_event_stats(post_id) do
      {:ok, stats} ->
        json(conn, %{stats: stats})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  @doc """
  GET /api/v1/events/available
  Получить список доступных событий.
  """
  def available_events(conn, params) do
    filters = %{
      location: params["location"],
      lat: parse_float(params["lat"]),
      lng: parse_float(params["lng"]),
      radius_km: parse_float(params["radius_km"])
    }

    events = Posts.list_available_events(filters)

    conn
    |> json(%{
      events: Enum.map(events, &format_event/1),
      count: length(events)
    })
  end

  @doc """
  GET /api/v1/my-events
  Получить события пользователя.
  """
  def my_events(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    events = Posts.get_user_events(user.id)

    conn
    |> json(%{
      created_events: Enum.map(events.created, &format_event/1),
      participating_events: Enum.map(events.participating, &format_event/1)
    })
  end
  defp format_event(post) do
    format_post(post)
    |> Map.merge(%{
      current_participants: post.current_participants,
      max_participants: post.max_participants,
      available_spots: (post.max_participants || 0) - (post.current_participants || 0),
      event_date: post.event_date,
      is_full: (post.current_participants || 0) >= (post.max_participants || 0)
    })
  end

  defp get_join_error_message(reason) do
    case reason do
      "Post is not an event" -> "This is not an event"
      "Cannot join your own event" -> "You cannot join your own event"
      "Already joined this event" -> "You are already a participant"
      "Event is full" -> "Sorry, this event is full"
      "Event has already passed" -> "This event has already ended"
      _ -> "Unable to join event"
    end
  end

  defp get_leave_error_message(reason) do
    case reason do
      "Post is not an event" -> "This is not an event"
      "Cannot leave your own event" -> "You cannot leave your own event"
      "You are not a participant" -> "You are not a participant of this event"
      _ -> "Unable to leave event"
    end
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
