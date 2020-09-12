defmodule GobletWeb.MatchMakerChannel do
  use GobletWeb, :channel
  alias Goblet.MatchFunction
  intercept ["found", "not_found"]



@doc """
    player_details :
    - player_id
    - room_name
    - player_count
  """
  def join("match_maker:"<>_room_id, player_details, socket) do
    MatchFunction.send_to_queue(player_details)
    {:ok, socket}
  end

  def handle_in("find_match", payload, socket) do
    search_params = %{
      "player_id" => payload["player_id"],
      "room_name" => payload["room_name"],
      "player_count" => payload["player_count"] |> String.to_integer,
    }
    _match_data = MatchFunction.find_match(search_params)

    ####
    ##  send after is_player in ets
    ####

    # MatchFunction.get_match(search_params)
    {:noreply, socket}
  end

  def handle_in("find_match_by_id", payload, socket) do
    search_params = %{
      "player_id" => payload["player_id"],
      "room_name" => payload["room_name"],
      "match_id"  => payload["match_id"],
      "player_count" => payload["player_count"] |> String.to_integer,
    }
    _match_data = MatchFunction.find_match_by_id(search_params)
    {:noreply, socket}
  end

  def handle_out("found", match_data, socket) do
    send_matchdata(match_data, socket)
    {:noreply, socket}
  end

  def terminate(reason, arg1) do

  end

  defp send_matchdata(match_data, socket) do
    %{"players" => players_list, "match_id" => _match_id } = match_data
    if should_send_match_info?(socket, players_list) do
      push(socket, "mm_event", match_data)
    end
  end

  defp should_send_match_info?(socket, player_ids) do
    Enum.any?(player_ids, fn player_id ->
      player_id === socket.assigns.player_id
    end)
  end

end
