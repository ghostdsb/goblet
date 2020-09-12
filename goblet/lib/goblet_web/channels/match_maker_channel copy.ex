defmodule GobletWeb.MatchMakerChannel2 do
  use GobletWeb, :channel
  alias Goblet.MatchFunction


  @doc """
    player_details :
    - player_id
    - room_name
    - player_count

      game_room namestructure ->
        "room_name:player_count" -> %{player_count: }
        or
        "room_name:match_id:player_count" -> -> %{player_count: , match_id: }
  """
  def join("match_maker:"<>_room_id, player_details, socket) do
    MatchFunction.send_to_queue(player_details)
    {:ok, socket}
  end
end
