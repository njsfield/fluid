defmodule Fluid.PageController do
  use Fluid.Web, :controller
  alias Ecto.UUID

  # Generate user_id
  # Assign both & serve with index.html
  def index(conn, _params) do
    user_id = UUID.generate
    conn
    |> assign(:user_id, user_id)
    |> assign(:socket_url, Application.get_env(:fluid, Fluid.Endpoint)[:socket_url])
    |> render("index.html")
  end
end
