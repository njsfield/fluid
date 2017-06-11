defmodule Fluid.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "user:*", Fluid.UserChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket

  # Connect ->  assign name & generate unique ID

  def connect(%{"name" => name}, socket) do
    {:ok, socket
      |> assign(:name, name)
      |> assign(:id, Ecto.UUID.generate)
    }
  end

  # Else
  def connect(_params, _socket) do
    {:error}
  end

  # Allow ID
  def id(socket), do: socket.assigns.id
end
