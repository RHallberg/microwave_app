defmodule MicrowaveWeb.PageController do
  use MicrowaveWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
