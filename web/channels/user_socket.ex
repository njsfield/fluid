defmodule Fluid.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "user:*", Fluid.UserChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket

  # Connect ->  assign name & generate unique ID

  def connect(%{"name" => name}, socket) do
    socket = assign(socket, :name, name)
    socket = assign(socket, :id, Ecto.UUID.generate)
    {:ok, socket}
  end

  # Else
  def connect(_params, _socket) do
    {:error}
  end

  # Allow ID
  def id(socket), do: socket.assigns.id
end
