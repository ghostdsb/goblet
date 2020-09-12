defmodule Goblet.MatchFunction2 do
  use GenServer
  require Logger

  ##################

  def start_link([]) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def send_to_queue(player_details) do
    GenServer.cast(__MODULE__, {"send_to_queue", player_details})
  end

  #################

  @impl true
  def init(:ok) do
    Logger.info("...MatchMaker Started...")
    create_ets()
    {:ok, []}
  end

  @impl true
  def handle_cast({"send_to_queue", player_details}, socket) do
    player_details |> handle_room_entry()

    '''
    get_game_queue
    |> push_player_to_queue(player_details)
    |>

    push_player_to_queue([], player_details) -> ets.insert(game_room, Map.new([{player_id, player_details_map}]))

    if game_room available in ets
      -> if player_id key in map
          ->nil
      else
        if Count(Map.keys(game_queue)) >= count-1
            pull count-1 players and self in a list |> send to match_builder
        else
            Map.put(game_queue_map, player_id, player_details_map)
    else ets.insert(game_room, Map.new([{player_id, player_details_map}]))



    '''

    {:noreply, socket}
  end

################

  defp create_ets() do
    :ets.new(:match_table, [:named_table])
    Logger.info("ETS Created")
  end

  defp handle_room_entry(player_details) do
    room_name = player_details["room_name"]

    room_name
    |> get_map_players_in_room()
    |> put_player_in_room(player_details)
  end

  defp get_map_players_in_room(room_name) do
    case :ets.lookup(:match_table, room_name) do
      [{_room_name_key, map_players_in_room}] ->
        map_players_in_room
      _ ->
        Logger.info("Not yet inserted anything")
        []
    end
  end



  defp put_player_in_room([], player_details) do
    player_id = player_details["player_id"]
    game_room = player_details["room_name"]
    match_id = player_details["match_id"] || ""
    map_first_player_in_room = Map.new([{player_id, %{"match_id" => match_id}}])
    ets_insert_into_room_collection(map_first_player_in_room, game_room)
  end

  defp put_player_in_room(map_players_in_room, player_details) do
    player_id = player_details["player_id"]
    player_count = player_details["player_count"]
    players_in_room_count = map_players_in_room |> Map.keys |> Enum.count

    put_player_in_room(
      map_players_in_room,
      player_details,
      Map.has_key?(map_players_in_room,player_id),
      players_in_room_count + 1 >= player_count
      )
  end

  defp put_player_in_room(map_players_in_room, player_details, player_in_room?, sufficient_players?)
  defp put_player_in_room(map_players_in_room, player_details, false, true) do
    game_room = player_details["room_name"]
    player_id = player_details["player_id"]
    player_count = player_details["player_count"]
    match_id = player_details["match_id"] || ""

    player_ids =
      map_players_in_room
      |>  Map.keys
      |> Enum.take(player_count-1)

    map_players_in_room =
      player_ids
      |> Enum.reduce(map_players_in_room, fn x,acc -> Map.delete(acc, x) end)
    player_id_list = [player_id| player_ids]
    ets_insert_into_room_collection(map_players_in_room,game_room)

    make_match(game_room, player_id_list, match_id)
  end
  defp put_player_in_room(map_players_in_room, player_details, true, true) do
    game_room = player_details["room_name"]
    player_id = player_details["player_id"]
    player_count = player_details["player_count"]
    match_id = player_details["match_id"] || ""

    map_players_in_room = Map.delete(map_players_in_room, player_id)

    player_ids =
      map_players_in_room
      |> Map.keys
      |> Enum.take(player_count-1)

    map_players_in_room =
      player_ids
      |> Enum.reduce(map_players_in_room, fn x,acc -> Map.delete(acc, x) end)

    player_id_list = [player_id| player_ids]
    ets_insert_into_room_collection(map_players_in_room,game_room)

    make_match(game_room, player_id_list, match_id)
  end
  defp put_player_in_room(_map_players_in_room, _player_details, _player_in_room?, false), do: nil


  defp make_match(game_room, player_id_list, match_id) do
    match_id =
      case match_id do
      "" ->  UUID.uuid4()
      _ -> match_id
    end
    match_details = %{
      "players" => player_id_list,
      "match_id" => match_id
    }
    GobletWeb.Endpoint.broadcast!("match_maker:#{game_room}", "match_success", match_details)
  end

  defp ets_insert_into_room_collection(player_map, game_room) do
    :ets.insert(:match_table, {game_room, player_map})
  end

  defp ets_insert_into_player_collection(players_map) do
    :ets.insert(:match_table, {"players", players_map})
  end

  defp update_player_map(player_id, game_room) do
    get_map_players_in_lobby()
    |> update_player_map(player_id, game_room)
    |> ets_insert_into_player_collection
  end

  defp update_player_map([],player_id, game_room) do
    %{player_id => game_room}
  end
  defp update_player_map(player_map,player_id, game_room) do
    Map.put player_map, player_id, game_room
  end

  defp ets_remove_player_data(player_id) do
    get_map_players_in_lobby()
    |> remove_player_entry(player_id)
  end

  defp remove_player_entry([], _player_id), do: nil
  defp remove_player_entry(player_map, player_id) do
    remove_player_entry(player_map, player_id, Map.has_key?(player_map,player_id))
  end
  defp remove_player_entry(player_map, player_id, true) do
    game_room = player_map[player_id]
    player_map |> Map.delete(player_id) |> ets_insert_into_player_collection
    game_room
    |> get_map_players_in_room()
    |> Map.delete(player_id)
    |> ets_insert_into_room_collection(game_room)
  end
  defp remove_player_entry(player_map, player_id, false), do: nil

  defp get_map_players_in_lobby() do
    case :ets.lookup(:match_table, "players") do
      [{_room_name_key, map_players_in_lobby}] ->
        map_players_in_lobby
      _ ->
        Logger.info("Not yet inserted anything")
        []
    end
  end
end
