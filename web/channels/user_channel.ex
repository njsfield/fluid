defmodule Fluid.UserChannel do
  use Phoenix.Channel
  require Logger

  # 2. Join 
  # Only allow users to join subtopic that matches ID 
  def join("user:" <> user_id, _msg, %{id: id} = socket) when user_id == id do
    {:ok, socket}
  end

  # Block other join attempts 
  def join("user:" <> _invalid, _msg, _socket) do 
    {:error, %{reason: "invalid user ID"}}
  end

  # 6. Valid Msg from Remote
  # (both users have assigned each others ids)
  def handle_in("msg", %{"body" => body}, %{assigns: %{remote_id: remote_id, user_id: user_id}} = socket) do
    # Forward message along with user_id & remote_id
    Fluid.Endpoint.broadcast("user:#{remote_id}", "msg", %{
      "body"    => body, 
      "user_id" =>  user_id 
    })
    {:noreply, socket}
  end

  # 3. Connect Msgs 
  # (both users must send this to allow messaging)
  def handle_in("msg", msg, %{assigns: %{user_id: user_id}} = socket) do
    case msg do
      # Wants to connect
      %{"name" => name, "remote_id" => remote_id} ->
        # Then attempt to broadcast to that user (give them user_id for their remote id)
        Fluid.Endpoint.broadcast("user:#{remote_id}", "msg", %{"remote_id" => user_id, "name" => msg["name"]})
        {:noreply, assign(socket, :remote_id, remote_id)}
      # Doesn't want to connect
      _ ->
        # Broadcast denied message
        Fluid.Endpoint.broadcast("user:#{msg.remote_id}", "msg", %{"error": "denied"})
        {:noreply, socket}
    end
  end

  # 4. Handle outgoing
  intercept ["msg"]

  # 6.1 Valid Msg to User
  # Only forward "msg:new" if user_id in message is remote_id in socket
  def handle_out("msg", %{"user_id" => user_id, "body" => body}, %{assigns: %{remote_id: remote_id}} = socket) when user_id == remote_id do 
    # Push new msg
    push socket, "msg:new", %{"body" => body} 
    {:noreply, socket}
  end

  # 5.1 Accept/Denied Msg to remote
  # In this state, remote does have remote_id assigned to socket
  # Therefore check message to see if user info is being sent from user 
  def handle_out("msg", msg, %{assigns: %{remote_id: _remote_id}} = socket) do
    case msg do
      # If they're providing their user info 
      %{"name" => _name, "remote_id" => _remote_id} ->
        # Send accept message 
        push socket, "msg:accept", msg
        {:noreply, socket}
      # If not 
      _ ->
        # Send denied message
        push socket, "msg:denied", msg
        {:noreply, socket}
    end
  end

  # 5. Connect Msg
  # In this state, user does NOT have remote_id assigned to socket
  # Therefore they should be prompted whether to connect
  def handle_out("msg", msg, socket) do
    # Push connect msg
    push socket, "msg:connect", msg
    {:noreply, socket}
  end

end
