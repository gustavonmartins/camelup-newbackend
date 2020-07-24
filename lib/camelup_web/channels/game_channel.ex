defmodule CamelupWeb.GameChannel do
  use CamelupWeb, :channel
  alias CamelUp.{GameSaloon, GameTable, GameTablePrivateView}

  @dummy_game_id 1

  def join("games:" <> game_id, %{"name" => uname}, socket) do
    game_id = game_id |> String.to_integer()
    socket = assign(socket, :game_user, %{:uuid => socket.assigns.user_id, :char => uname})
    send(self(), :after_join)
    {:ok, assign(socket, :game_id, game_id)}
  end

  def handle_info(:after_join, socket) do
    gs_base =
      case :ets.lookup(:game_cache, :main) do
        [{:main, %GameSaloon{} = gs}] -> gs
        [] -> %GameSaloon{}
      end

    gs =
      gs_base
      |> GameSaloon.be_joined_by_user(socket.assigns.game_user, socket.assigns.game_id)

    {:ok, %GameTable{} = it} =
      gs
      |> GameSaloon.get_table_by_id(socket.assigns.game_id)

    :ets.insert(:game_cache, {:main, gs})

    it2 = it |> GameTablePrivateView.to_view(socket.assigns.game_user.char)
    # push(socket, "broadcast_game_table", it2)
    broadcast!(socket, "broadcast_game_table", it2)
    socket |> IO.inspect(label: "socket is: ")
    {:noreply, socket}
  end

  def terminate(_, socket) do
    gs_base =
      case :ets.lookup(:game_cache, :main) do
        [{:main, %GameSaloon{} = gs}] -> gs
      end

    gs =
      gs_base
      |> GameSaloon.be_left_by_user(socket.assigns.game_user)

    :ets.insert(:game_cache, {:main, gs})

    :ok
  end

  @spec handle_in(String.t(), any, Phoenix.Socket.t()) :: {:noreply, Phoenix.Socket.t()}
  def handle_in("decision", %{"first" => fst, "second" => snd, "third" => trd}, socket) do
    action =
      case fst do
        "warmup" -> :warmup
        "start" -> :start
        "shake" -> :shake
        "got_leg_money" -> :got_leg_money
        "bet_on_leg" -> :bet_on_leg
      end

    [{:main, %GameSaloon{} = gs}] = :ets.lookup(:game_cache, :main)
    gs = gs |> GameSaloon.user_action(socket.assigns.game_user, action)
    table_id = gs |> GameSaloon.get_user_table_id(socket.assigns.game_user.uuid)
    {:ok, gt} = gs |> GameSaloon.get_table_by_id(table_id)
    gt2 = gt |> GameTablePrivateView.to_view(socket.assigns.game_user.char)
    broadcast!(socket, "broadcast_game_table", gt2)

    :ets.insert(:game_cache, {:main, gs})

    {:noreply, socket}
  end
end
