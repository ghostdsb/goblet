defmodule GobletWeb.Router do
  use GobletWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/goblet", GobletWeb do
    pipe_through :api

    post "/v1/get-match", MatchController, :get_match       # usual matchmaking
    post "/v1/get-by-id", MatchController, :get_by_id      # player has match_id
    post "/v1/get-by-filter", MatchController, :get_match  # filter by a property(no match_id)
  end
end


# POST API instead of get
