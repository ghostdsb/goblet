defmodule GobletWeb.Router do
  use GobletWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/goblet", GobletWeb do
    pipe_through :api

    get "/v1/:room_name/:player_id/:max_players", QManagementController, :index
    get "/v1/:room_name", QManagementController, :get_all
  end
end
