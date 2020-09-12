defmodule Goblet.MatchFunction do
  use GenServer
  require Logger

  ##################
  # Client functions
  ##################

  def start_link([]) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def send_to_queue(player_details) do
    GenServer.cast(__MODULE__, {"send_to_queue", player_details})
  end

  @doc """
    search_params :
    - player_id
    - room_name
    - player_count
    - others (some delimiter) [TO DO]
  """
  def find_match(search_params) do
    GenServer.call(__MODULE__, {"find_match", search_params})
  end


  @doc """
    search_params :
    - player_id
    - room_name
    - match_id
  """
  def find_match_by_id(search_params) do
    GenServer.call(__MODULE__, {"find_match_by_id", search_params})
  end

  def get_all(room_name) do
    GenServer.call(__MODULE__, {"get_all", room_name})
  end


  def get_match(search_params) do
    GenServer.cast(__MODULE__, {"get_match", search_params})
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

  @impl true
  def handle_call({"find_match_by_id", search_params}, _from,  state) do
    Logger.info(inspect(search_params))
    ets_key_name = search_params["room_name"]<>":"<>search_params["match_id"]<>":"<>"#{search_params["player_count"] |> Integer.to_string}"
    match_data = get_game_queue_by_matchid(ets_key_name)
                  |> get_available_player_list(%{
                    "room_name" => ets_key_name,
                    "player_id" => search_params["player_id"],
                    "player_count" => search_params["player_count"]
                  })

    {:reply, match_data, state}
  end

  def handle_call({"get_all", room_name}, _from,  state) do

    room_data = room_name |> get_game_queue

    {:reply, room_data, state}
  end

  @impl true
  def handle_cast({"send_to_queue", player_details}, socket) do
    push_player_to_queue(player_details)
    {:noreply, socket}
  end

  @impl true
  def handle_info({"search_again", search_params}, socket) do
    ets_key_name = search_params["room_name"]<>":"<>search_params["match_id"]<>":"<>"#{search_params["player_count"] |> Integer.to_string}"
    get_game_queue_by_matchid(ets_key_name)
    |> get_available_player_list(%{
      "room_name" => ets_key_name,
      "player_id" => search_params["player_id"],
      "player_count" => search_params["player_count"]
    })
    {:noreply, socket}
  end


  # def handle_cast({"get_match", search_param}, state) do
  #   #search in queue room_id:playercount
  #   #if no queue create queue-> push(%{player_id: "gzp_0", match_id: "", tries: 0}) -> process.semd_after(search_param)
  #   #found queue -> search player_id -> if found -> if length < player_count-1 -> increase tries += 1 ->  process.semd_after(search_param)
  #   #                                               else
  # end
  ##################
  # Helper functions
  ##################

  defp create_ets() do
    :ets.new(:match_table, [:named_table])
    Logger.info("ETS Created")
  end


  defp push_player_to_queue(player_details) do
    game_queue = get_game_queue(player_details["room_name"])
    push_player_to_queue(game_queue, player_details)
  end
  defp push_player_to_queue([], player_details) do
    :ets.insert(:match_table, {player_details["room_name"], %{player_details["player_id"] => %{"player_count" => player_details["player_count"]}}})
  end
  defp push_player_to_queue(game_queue, player_details) do
    cond do
      should_push_player?(game_queue, player_details["player_id"]) ->
        :ets.insert(:match_table, {player_details["room_name"], Map.put(game_queue,player_details["player_id"], %{"player_count" => player_details["player_count"]})})
      true -> nil
    end
  end

  defp should_push_player?(game_queue, player_id) do
      !Map.has_key?(game_queue, player_id)
  end


  # returns player list of a game_room
  # [p1, p2, p3 ...] // []
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
      Enum.count(players)>= search_params["player_count"]-1 ->
        player_list = players |> Enum.take(search_params["player_count"]-1)
        :ets.insert(:match_table, {search_params["room_name"], players--player_list})
        create_match([search_params["player_id"]| player_list], search_params["room_name"])
      true ->
        cond do
          Enum.any?(game_queue, fn player_id -> player_id == search_params["player_id"] end) ->
            %{"match_id" => "", "players" => []}
          true ->
            add_player_to_queue(game_queue, search_params)
        end
    end
  end

  defp create_match(player_list, room_name) do
    match_data = %{"players" => player_list, "match_id" => UUID.uuid4()}
    Logger.info("Match Data")
    Logger.info(inspect(match_data))
    # match_data
    GobletWeb.Endpoint.broadcast!("match_maker:#{room_name}", "match_success", match_data)
  end

  defp add_player_to_queue([], search_params) do
    :ets.insert(:match_table, {search_params["room_name"], [search_params["player_id"]]})
    Process.send_after(self(),{"search_again", search_params}, 10000)
    %{"players" => [], "match_id" => ""}
  end

  defp add_player_to_queue(game_queue, search_params) do
    Logger.info("Opponent Not available in Queue, Adding to Queue")
    :ets.insert(:match_table, {search_params["room_name"], [search_params["player_id"] | game_queue]})
    Process.send_after(self(),{"search_again", search_params}, 10000)
    %{"players" => [], "match_id" => ""}
  end

  defp get_game_queue_by_matchid(ets_key_name) do
    case :ets.lookup(:match_table, ets_key_name) do
      [{_room_name_key, game_queue}] ->
        game_queue

      _ ->
        Logger.info("Not yet inserted anything")
        []
    end
  end

  # defp retry_matching(match_param) do
  #   Process.send_after(self(), {"retry", match_params})
  # end
end
