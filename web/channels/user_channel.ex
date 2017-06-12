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

end
