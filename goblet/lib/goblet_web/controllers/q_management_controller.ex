defmodule GobletWeb.QManagementController do
  use GobletWeb, :controller
  alias Goblet.MatchWorker
  require Logger


  @doc """
    params :
    - player_id (string)
    - room_name (string)
    - max_players (integer)
    - others (some delimiter) [TO DO]
  """
  def index(conn, params) do
    Logger.info("params ->#{inspect(conn)}")
    match_data = MatchWorker.find_match(%{
      "player_id" => params["player_id"],
      "room_name" => params["room_name"],
      "max_players" => params["max_players"] |> String.to_integer,
    })
    json(conn, match_data)
  end

  @doc """
   params :
    - room_name (string)
  """
  def get_all(conn, params) do
    get_room_data = MatchWorker.get_all(params["room_name"])
    json(conn, get_room_data)
  end
end
