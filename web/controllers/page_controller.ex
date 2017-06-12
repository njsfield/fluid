defmodule Fluid.PageController do
  use Fluid.Web, :controller
  alias Ecto.UUID
  alias Phoenix.Token

  # Generate user_id & create token
  # Assign both & serve with index.html
  def index(conn, _params) do
    user_id = UUID.generate
    conn
    |> assign(:user_token, Token.sign(Fluid.Endpoint, "user_token", user_id))
    |> assign(:user_id, user_id)
    |> render("index.html")
  end
end
