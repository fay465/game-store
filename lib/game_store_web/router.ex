defmodule GameStoreWeb.Router do
  use GameStoreWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GameStoreWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :ensure_cart_token
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", GameStoreWeb do
    pipe_through :api


    # Carros
    post "/carts", CartController, :create
    get "/carts/:token", CartController, :show
    delete "/carts/:token", CartController, :clear


    post "/carts/:token/items", CartController, :add_item
    patch "/carts/:token/items/:id", CartController, :update_item
    delete "/carts/:token/items/:id", CartController, :remove_item

    post "/carts/:token/checkout", CartController, :checkout

  end

  scope "/", GameStoreWeb do
    pipe_through :browser
    live "/", CatalogLive, :index
    live "/cart", CartHyperLive, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", GameStoreWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:game_store, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GameStoreWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end

  defp ensure_cart_token(conn, _opts) do
    case get_session(conn, :cart_token) do
      nil ->
        token = Ecto.UUID.generate()
        GameStore.Cart.get_or_create_cart(token)
        put_session(conn, :cart_token, token)

      token ->
        case GameStore.Cart.fetch_cart(token) do
          %GameStore.Cart.Cart{status: "closed"} ->
            # si el carro está cerrado, generamos uno nuevo y lo guardamos en sesión
            new = Ecto.UUID.generate()
            GameStore.Cart.get_or_create_cart(new)
            put_session(conn, :cart_token, new)

          _ ->
            conn
        end
    end
  end
end
end
