defmodule GobletWeb.RaceConditionTest do
  use GobletWeb.ConnCase, async: true
  use Plug.Test
  alias GobletWeb.Router
  require Logger

  test '1 player - both max_players: 2' do
    response = conn(:get, "/goblet/v1/room/a/2") |> send_request()
    assert response.resp_body|>get_players == []
  end

  test '2 players - same match - both max_players: 2' do
    conn(:get, "/goblet/v1/room/a/2")|> send_request()
    response = conn(:get, "/goblet/v1/room/b/2") |> send_request()
    assert response.resp_body|>get_players == ["b","a"]
  end

  test '2 players - same match - both max_players: 3' do
    conn(:get, "/goblet/v1/room/a/3")|> send_request()
    response = conn(:get, "/goblet/v1/room/b/3") |> send_request()
    assert response.resp_body|>get_players == []
  end

  test '3 players - same match - all max_players: 3' do
    conn(:get, "/goblet/v1/room/a/3")|> send_request()
    conn(:get, "/goblet/v1/room/b/3")|> send_request()
    response = conn(:get, "/goblet/v1/room/c/3") |> send_request()
    assert response.resp_body|>get_players == ["c","b","a"]
  end

  defp get_players(resp_body) do
    {:ok, %{"match_id" => _match_id, "players" => players}} = Jason.decode(resp_body)
    players
  end

  defp send_request(conn) do
    conn
    |> put_private(:plug_skip_csrf_protection, true)
    |> GobletWeb.Endpoint.call([])
  end
end
