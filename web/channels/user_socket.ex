defmodule Fluid.UserSocket do
  use Phoenix.Socket
  alias Phoenix.Token

  ## Channels
  channel "user:*", Fluid.UserChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket

  # Connect 
  # Each socket provides name & ID (from token)
  # Token is verified, then params are assigned to socket
  # An additional remote_id is first assigned initially as 'nil'

  def connect(%{"user_token" => user_token, "name" => name}, socket) do
    case Token.verify(socket, "user_token", user_token) do
      {:ok, user_id} -> 
        {:ok, socket
          |> assign(:name, name)
          |> assign(:user_id, user_id)
          |> assign(:remote_id, nil)
         }
      {:error, _} ->
        :error
    end
  end

  def connect(_params, _socket) do
    :error
    
  end

  # Assign User ID as ID
  def id(socket), do: socket.assigns.user_id
end
