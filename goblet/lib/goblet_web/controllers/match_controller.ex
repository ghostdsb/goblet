defmodule GobletWeb.MatchController do
  use GobletWeb, :controller
  alias Goblet.MatchFunction
  require Logger


  @doc """
    params :
    - player_id (string)
    - room_name (string)
    - player_count (integer)
    - others (some delimiter) [TO DO]
  """
  def get_match(conn, params) do
    Logger.info(" conn-> #{inspect(conn)}, params -> #{inspect(params)}")
    match_data = MatchFunction.find_match(%{
      "player_id" => params["player_id"],
      "room_name" => params["room_name"],
      "player_count" => params["player_count"] |> String.to_integer,
    })
    json(conn, match_data)
  end


  def get_by_id(conn, params) do
    Logger.info(" conn-> #{inspect(conn)}, params -> #{inspect(params)}")
    match_data = MatchFunction.find_match_by_id(%{
      "player_id" => params["player_id"],
      "room_name" => params["room_name"],
      "match_id"  => params["match_id"],
      "player_count" => params["player_count"] |> String.to_integer,
    })
    json(conn, match_data)
  end
end
