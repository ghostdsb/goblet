defmodule Goblet.MatchWorker do
  use GenServer
  require Logger

  #####################
  # Client functions
  #####################

  def start_link([]) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
    search_params :
    - player_id
    - room_name
    - max_players
    - others (some delimiter) [TO DO]
  """
  def find_match(search_params) do
    GenServer.call(__MODULE__, {"find_match", search_params})
  end

  def get_all(room_name) do
    GenServer.call(__MODULE__, {"get_all", room_name})
  end

  ##################
  # Server Callbacks
  ##################

  @impl true
  def init(:ok) do
    # Here we have to create an ETS.
    # We dont need an expiry actually because we try to empty the queue anyway.
    Logger.info("...MatchMaker Started...")
    create_ets()

    {:ok, []}
  end


  @impl true
  def handle_call({"find_match", search_params}, _from,  state) do
    Logger.info(inspect(search_params))

    match_data = get_game_queue(search_params["room_name"])
                  |> get_available_player_list(search_params)

    {:reply, match_data, state}
  end

  def handle_call({"get_all", room_name}, _from,  state) do

    room_data = room_name |> get_game_queue

    {:reply, room_data, state}
  end

  ##################
  # 	Helper functions
  ##################

  defp create_ets() do
    :ets.new(:match_table, [:named_table])
    Logger.info("ETS Created")
  end

  defp get_game_queue(room_name) do
    case :ets.lookup(:match_table, room_name) do
      [{_room_name_key, game_queue}] ->
        game_queue

      _ ->
        Logger.info("Not yet inserted anything")
        []
    end
  end

  defp get_available_player_list([], search_params), do: add_player_to_queue([], search_params)
  defp get_available_player_list(game_queue, search_params) do
    players = game_queue |> Enum.filter(fn player_id -> player_id != search_params["player_id"] end)

    cond do
      Enum.count(players)>= search_params["max_players"]-1 ->
        player_list = players |> Enum.take(search_params["max_players"]-1)
        :ets.insert(:match_table, {search_params["room_name"], players--player_list})
        create_match([search_params["player_id"]| player_list])
      true ->
        cond do
          Enum.any?(game_queue, fn player_id -> player_id == search_params["player_id"] end) ->
            %{"match_id" => "", "players" => []}
          true ->
            add_player_to_queue(game_queue, search_params)
        end
    end
  end

  defp create_match(player_list) do
    match_data = %{"players" => player_list, "match_id" => UUID.uuid4()}
    Logger.info("Match Data")
    Logger.info(inspect(match_data))
    match_data
    # HagridWeb.Endpoint.broadcast!("#{player_a["gamecode"]}:lobby", "match_success", match_data)
  end

  defp add_player_to_queue([], search_params) do
    :ets.insert(:match_table, {search_params["room_name"], [search_params["player_id"]]})
    %{"players" => [], "match_id" => ""}
  end

  defp add_player_to_queue(game_queue, search_params) do
    Logger.info("Opponent Not available in Queue, Adding to Queue")
    :ets.insert(:match_table, {search_params["room_name"], [search_params["player_id"] | game_queue]})
    %{"players" => [], "match_id" => ""}
  end
end
