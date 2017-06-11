defmodule Fluid.UserChannel do
  use Phoenix.Channel
  require Logger

  # Let User join lobby, then reply with user id so they can join a unique channel
  def join("user:lobby", _msg, %{id: id} = socket) do
    {:ok, %{user_id: id}, socket}
  end

  # Join (optional message containing remote ID)
  def join("user:" <> user_id, msg, socket) do
    # Check if Remote is requesting to join User
    if (Map.has_key?(msg, "remote_id")) do
      # Send to User
      send(self(), {:remote_joined, msg})
    end
    {:ok, %{user_id: user_id}, socket}
  end

  # # User join. No message
  # def join("user:" <> user_id, _msg, socket) do
  #   {:ok, %{user_id: user_id}, socket}
  # end

  # Notify User that Remote wants to join
  def handle_info({:remote_joined, %{"remote_id" => remote_id}}, socket) do
    msg_for_user = %{name: socket.assigns.name, remote_id: socket.id}
    # Broad to remote
    Fluid.Endpoint.broadcast("user:#{remote_id}", "connect", msg_for_user)
    {:noreply, socket}
  end

  # (After alert) Response from User
  def handle_in("request:" <> result, msg, socket) do
    # Determine whether user sent "accept" or "denied"
    case result do
      "accept" ->
        # Send to remote
        IO.inspect(msg)
        send(self(), {:user_accepts, msg})
        {:noreply, socket}
      "denied" ->
        # If denied don't reply
        {:noreply, socket}
    end
  end

  # Notify Remote that User has accepted
  def handle_info({:user_accepts, %{"remote_id" => remote_id} = msg}, socket) do
    # Broad to remote
    Fluid.Endpoint.broadcast("user:#{remote_id}", "handle:accept", msg)
    {:noreply, socket}
  end

  # # Handle msg (1st time)
  # def handle_in({"msg" <> key, %{"remote_key" => remote_key, "remote_id" => remote_id} = msg}, socket) do
  #   send(self(), {"msg" <> key, msg})
  #   {:noreply, socket}
  # end
  # # Notify Remote that User has accepted
  # def handle_info({"msg" <> key, %{"remote_key" => remote_key, "remote_id" => remote_id} = msg}, socket) do
  #   # Broad to remote
  #   socket
  #   |> assign()
  #   Fluid.Endpoint.broadcast("user:#{remote_id}", "msg:#{key}", msg)
  #   {:noreply, socket}
  # end


  def terminate(reason, _socket) do
    Logger.debug"> leave #{inspect reason}"
    :ok
  end

end
