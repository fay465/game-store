defmodule GameStoreWeb.PageController do
  use GameStoreWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
