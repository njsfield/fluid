defmodule Fluid.UserChannel do
  use Phoenix.Channel
  alias Fluid.MyTracker
  alias Fluid.Endpoint
  alias Phoenix.Tracker
  require Logger




  ### Join




  # Users with ids only join dedicated subtopic
  def join("user:" <> user_id, _msg, %{id: id} = socket)
    when user_id == id do
    # Track Topic & Socket
    Tracker.track(MyTracker, self(), "user:#{user_id}", id, %{stat: "here"})
    {:ok, socket}
  end

  # Block others
  def join("user:" <> _invalid, _msg, _socket) do
    :error
  end




  ### Incoming




  # Request
  def handle_in("request", %{"name" => name, "remote_id" => remote_id}, socket) do
    # Check socket is active
    case (Tracker.list(MyTracker, "user:#{remote_id}")) do
      [] ->
        # Socket Unknown. Broadcast Deny
        broadcast socket, "deny", %{"body" => "User unavailable"}
        {:noreply, socket}
       _ ->
        # Broadcast to remote & assign remote_id
        Endpoint.broadcast("user:#{remote_id}", "request", %{
          "name"    => name,
          "user_id" => socket.id
        })
        {:noreply, assign(socket, :remote_id, remote_id)}
    end
  end

  # Accept
  def handle_in("accept", %{"name" => name, "remote_id" => remote_id}, socket) do
    # Broadcast to remote
    Endpoint.broadcast("user:#{remote_id}", "accept", %{
      "name"    => name,
      "user_id" => socket.id
    })
    {:noreply, assign(socket, :remote_id, remote_id)}
  end

  # Deny
  def handle_in("deny", %{"remote_id" => remote_id} = _msg, socket) do
    # Broadcast to remote
    Endpoint.broadcast("user:#{remote_id}", "deny", %{
      "body"    => "User has denied to connect"
    })
    {:noreply, socket}
  end

  # Msg
  def handle_in("message", %{"body" => body}, %{assigns: %{remote_id: remote_id}} = socket) do
    # Broadcast to user/remote (pass user_id from socket)
    Endpoint.broadcast("user:#{remote_id}", "message", %{
      "body"    => body,
      "user_id" => socket.id
    })
    {:noreply, socket}
  end

  # Ignore
  def handle_in(_topic, _msg, socket), do: {:noreply, socket}

  # Terminate
  def terminate(_reason, %{assigns: %{remote_id: remote_id, name: name}} = socket) do
    # Broadcast to remote (pass this users id and name)
    Endpoint.broadcast("user:#{remote_id}", "leave", %{
      "user_id" => socket.id,
      "name"    => name
    })
    :ok
  end




  ### Outgoing




  intercept ["message", "request", "accept", "deny", "leave"]




  # Request User
  def handle_out("request", %{"user_id" => user_id, "name" => name}, %{assigns: %{remote_id: remote_id}} = socket) do
    if (is_nil(remote_id)) do
      # Pass request when User has no remote_id stored
      push socket, "request", %{"name" => name, "remote_id" => user_id}
    else
      # If User has remote_id stored, broadcast back with deny
      Endpoint.broadcast("user:#{user_id}", "deny", %{
        "body"    => "User is busy"
      })
    end
    {:noreply, socket}
  end

  # Accept
  def handle_out("accept", %{"user_id" => user_id, "name" => name}, %{assigns: %{remote_id: _remote_id}} = socket) do
    # Send accept message
    push socket, "accept", %{"name" => name, "remote_id" => user_id}
    {:noreply, socket}
  end

  # Deny
  def handle_out("deny", msg, %{assigns: %{remote_id: _remote_id}} = socket) do
    # Send deny message
    push socket, "deny", msg
    # Reset remote_id to nil
    {:noreply, assign(socket, :remote_id, nil)}
  end

  # Message
  def handle_out("message", %{"user_id" => user_id, "body" => body}, %{assigns: %{remote_id: remote_id}} = socket)
    when user_id == remote_id do
    # Only push msg when User has matching remote_id stored in socket
    push socket, "message", %{"body" => body}
    {:noreply, socket}
  end

  # Leave
  def handle_out("leave", %{"user_id" => user_id, "name" => name}, %{assigns: %{remote_id: remote_id}} = socket)
    when user_id == remote_id do
    # Only push msg when User has matching remote_id stored in socket
    push socket, "leave", %{"body" => "#{name} has left"}
    # Reset remote_id to nil
    {:noreply, assign(socket, :remote_id, nil)}
  end

  # Ignore others
  def handle_out(_topic, _msg, socket), do: {:noreply, socket}

end
