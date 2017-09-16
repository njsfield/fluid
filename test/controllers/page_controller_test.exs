defmodule Fluid.PageControllerTest do
  use Fluid.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    conn.assigns
    assert Map.has_key?(conn.assigns, :user_id)
  end
end
