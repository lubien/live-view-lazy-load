defmodule LazyLoadExampleWeb.PageController do
  use LazyLoadExampleWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
