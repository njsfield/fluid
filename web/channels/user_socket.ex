defmodule Fluid.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "user:*", Fluid.UserChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket

  # Connect 
  # Each socket provides name & ID (from token)
  # Then params are assigned to socket
  # An additional remote_id is first assigned initially as 'nil'

  def connect(%{"user_id" => user_id, "name" => name}, socket) do
    {:ok, socket
      |> assign(:name, name)
      |> assign(:user_id, user_id)
      |> assign(:remote_id, nil)
    }
  end

  def connect(_params, _socket) do
    :error
    
  end

  # Assign User ID as ID
  def id(socket), do: socket.assigns.user_id
end
