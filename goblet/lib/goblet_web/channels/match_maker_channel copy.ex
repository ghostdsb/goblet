defmodule GobletWeb.MatchMakerChannel2 do
  use GobletWeb, :channel
  alias Goblet.MatchFunction
  intercept ["found", "not_found"]

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

  def handle_out("found", payload, socket) do
    send_matchdata(payload, socket)
    {:noreply, socket}
  end

  def handle_out("not_found", payload, socket)  do
    send_matchdata(payload, socket)
    {:noreply, socket}
  end

  def terminate(_reason, socket) do
    handle_on_terminate(socket)
    {:ok, socket}
  end

  ##################

  defp send_matchdata(payload, socket) do
    player_list = payload["players"]
    if should_send_match_info?(socket, player_list) do
      push(socket, "mm_event", payload)
    end
  end

  defp should_send_match_info?(socket, player_list) do
    Enum.any?(player_list, fn player_id ->
      player_id === socket.assigns.player_id
    end)
  end

  defp handle_on_terminate(socket) do
    MatchFunction.remove_player(socket.assigns.player_id)
  end
end
