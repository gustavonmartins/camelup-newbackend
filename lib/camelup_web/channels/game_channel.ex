defmodule CamelupWeb.GameChannel do
  use CamelupWeb, :channel
  alias CamelUp.{GameSaloon, GameTable, GameTablePrivateView}

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

  def handle_in("decision", %{"first" => fst, "second" => snd, "third" => trd}, socket) do
    action =
      case {fst, snd, trd} do
        {"warmup", _, _} ->
          :warmup

        {"start", _, _} ->
          :start

        {"shake", _, _} ->
          :shake

        {"get_leg_money", _, _} ->
          :get_leg_money

        {"bet_on_leg", color, _} ->
          case color do
            "black" -> {:bet_on_leg, :black}
            "blue" -> {:bet_on_leg, :blue}
            "green" -> {:bet_on_leg, :green}
            "orange" -> {:bet_on_leg, :orange}
            "red" -> {:bet_on_leg, :red}
          end

        {"get_final_winner_money", _, _} ->
          :get_final_winner_money

        {"get_final_looser_money", _, _} ->
          :get_final_looser_money
      end

    [{:main, %GameSaloon{} = gs}] = :ets.lookup(:game_cache, :main)

    gs = gs |> GameSaloon.user_action(socket.assigns.game_user, action)
    table_id = gs |> GameSaloon.get_user_table_id(socket.assigns.game_user.uuid)
    {:ok, gt} = gs |> GameSaloon.get_table_by_id(table_id)
    gt2 = gt |> GameTablePrivateView.to_view(socket.assigns.game_user.char)

    broadcast!(socket, "broadcast_game_table", gt2)

    :ets.insert(:game_cache, {:main, gs})

    {:reply, {:ok, %{}}, socket}
  end
end
