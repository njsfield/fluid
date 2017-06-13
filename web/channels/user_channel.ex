defmodule Fluid.UserChannel do
  use Phoenix.Channel
  require Logger

  ### Join 



  # Only allow users to join subtopic that matches ID 
  def join("user:" <> user_id, _msg, %{id: id} = socket) 
    when user_id == id do
    {:ok, socket}
  end

  # Block other join attempts 
  def join("user:" <> _invalid, _msg, _socket) do 
    :error 
  end



  ### Incoming 



  # Request 
  def handle_in("request", %{"name" => name, "remote_id" => remote_id}, socket) do
    # Broadcast to remote
    Fluid.Endpoint.broadcast("user:#{remote_id}", "request", %{
      "name"    => name,
      "user_id" => socket.id
    }) 
    {:noreply, assign(socket, :remote_id, remote_id)}
  end

  # Accept
  def handle_in("accept", %{"name" => name, "remote_id" => remote_id}, socket) do
    # Broadcast to user 
    Fluid.Endpoint.broadcast("user:#{remote_id}", "accept", %{
      "name"    => name
    })
    {:noreply, assign(socket, :remote_id, remote_id)}
  end

  # Deny
  def handle_in("deny", %{"remote_id" => remote_id}, socket) do
    # Broadcast to user 
    Fluid.Endpoint.broadcast("user:#{remote_id}", "deny", %{
      "body"    => "User has denied to connect" 
    })
    {:noreply, socket}
  end

  # Msg
  def handle_in("msg", %{"body" => body}, %{assigns: %{remote_id: remote_id}} = socket) do
    # Broadcast to remote (pass this users id) 
    Fluid.Endpoint.broadcast("user:#{remote_id}", "msg", %{
      "body"    => body, 
      "user_id" => socket.id 
    })
    {:noreply, socket}
  end

  # Ignore Others
  def handle_in(_topic, _msg, socket), do: {:noreply, socket}

  # Terminate cases
  def terminate(_reason, %{assigns: %{remote_id: remote_id, name: name}} = socket) do 
    # Broadcast to remote (pass this users id and name)
    Fluid.Endpoint.broadcast("user:#{remote_id}", "leave", %{
      "user_id" => socket.id,
      "name"    => name
    })
    :ok
  end


  ### Outgoing 
  


  intercept ["msg", "request", "accept", "deny", "leave"]

  # Request (Idle User)
  # Only pass request when User has no remote_id stored
  def handle_out("request", msg, %{assigns: %{remote_id: remote_id}} = socket) 
    when is_nil(remote_id) do
    # Push request 
    push socket, "request", msg
    {:noreply, socket}
  end

  # Request (Busy User)
  # When User already remote_id stored, send deny 
  def handle_out("request", %{"user_id" => user_id}, socket) do
    Fluid.Endpoint.broadcast("user:#{user_id}", "deny", %{
      "body"    => "User is busy" 
    })
    {:noreply, socket}
  end

  # Accept
  def handle_out("accept", msg, %{assigns: %{remote_id: _remote_id}} = socket) do
    # Send accept message 
    push socket, "accept", msg
    {:noreply, socket}
  end

  # Deny 
  def handle_out("deny", msg, %{assigns: %{remote_id: _remote_id}} = socket) do
    # Send accept message 
    push socket, "deny", msg
    {:noreply, assign(socket, :remote_id, nil)}
  end

  # Msg 
  # Verify Remotes user_id matches remote_id stored in Users socket 
  def handle_out("msg", %{"user_id" => user_id, "body" => body}, %{assigns: %{remote_id: remote_id}} = socket) 
    when user_id == remote_id do 
    # Push Msg
    push socket, "msg", %{"body" => body} 
    {:noreply, socket}
  end

  # Leave 
  # Verify Remotes user_id matches remote_id stored in Users socket 
  def handle_out("leave", %{"user_id" => user_id, "name" => name}, %{assigns: %{remote_id: remote_id}} = socket) 
    when user_id == remote_id do 
    # Push Msg
    push socket, "leave", %{"body" => "#{name} has left"} 
    {:noreply, assign(socket, :remote_id, nil)}
  end
  
  # Ignore others
  def handle_out(_topic, _msg, socket), do: {:noreply, socket}

end
