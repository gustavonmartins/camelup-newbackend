defmodule Camelup.GameBoardTest do
  use ExUnit.Case, async: true
  alias CamelUp.{GameBoard, GameBoardCase}
  doctest GameBoard

  defp pass_if_matches(item, match) do
    (fn x ->
       assert item = match
       x
     end).(item)
  end

  defp forbid_or_allow_actions(state, conditions) when is_map(conditions) do
    {forbiddenlist, allowedlist} =
      case Map.get(conditions, :allowonly) do
        nil ->
          a = Map.get(conditions, :allow, [])
          f = Map.get(conditions, :forbid, [])
          {f, a}

        list ->
          all = [
            :warmup,
            :start,
            :shake,
            :put_trap,
            :bet_on_leg,
            :bet_on_final_winner,
            :bet_on_final_looser,
            :get_leg_money,
            :get_final_winner_money,
            :get_final_looser_money
          ]

          a = list
          f = all -- a

          {f, a}
      end

    executelist = Map.get(conditions, :execute, [])

    actionfromsimple = fn action ->
      case action do
        :put_trap ->
          {:put_trap, :rand.uniform(20), {:oasis, :ana}}

        :bet_on_leg ->
          {:bet_on_leg, Enum.random([:black, :blue, :green, :orange, :red])}

        :bet_on_final_winner ->
          {:bet_on_final_winner, Enum.random([:black, :blue, :green, :orange, :red]), :ana}

        :bet_on_final_looser ->
          {:bet_on_final_looser, Enum.random([:black, :blue, :green, :orange, :red]), :bob}

        _ ->
          action
      end
    end

    {allowedlist, forbiddenlist, executelist} =
      {allowedlist |> Enum.map(actionfromsimple), forbiddenlist |> Enum.map(actionfromsimple),
       executelist |> Enum.map(actionfromsimple)}

    state |> forbid_or_allow_actions(:forbid, forbiddenlist)
    state |> forbid_or_allow_actions(:allow, allowedlist)
    state |> forbid_or_allow_actions(:execute, executelist)
  end

  defp forbid_or_allow_actions(item, forbidorallow, msglist) when is_list(msglist) do
    forbid_or_allow_action = fn item, forbidorallow, msg ->
      case forbidorallow do
        :forbid ->
          (fn x ->
             assert catch_error(x |> GameBoard.action(msg))
             x
           end).(item)

        :allow ->
          (fn x ->
             x |> GameBoard.action(msg)
             x
           end).(item)

        :execute ->
          (fn x ->
             x |> GameBoard.action(msg)
           end).(item)
      end
    end

    case msglist do
      [] ->
        item

      [head | []] ->
        item
        |> forbid_or_allow_action.(forbidorallow, head)

      [head | tail] ->
        item
        |> forbid_or_allow_action.(forbidorallow, head)
        |> forbid_or_allow_actions(forbidorallow, tail)
    end
  end

  describe "Pre warms the game and goes up to q1 state" do
    setup do
      res =
        %GameBoard{}
        |> pass_if_matches(%{state: :q0, dice: 5, finished: false})
        |> GameBoard.action(:warmup)
        |> pass_if_matches(%{state: :q0, dice: 4, finished: false})
        |> GameBoard.action(:warmup)
        |> pass_if_matches(%{state: :q0, dice: 3, finished: false})
        |> GameBoard.action(:warmup)
        |> pass_if_matches(%{state: :q0, dice: 2, finished: false})
        |> GameBoard.action(:warmup)
        |> pass_if_matches(%{state: :q0, dice: 1, finished: false})
        |> GameBoard.action(:warmup)
        |> pass_if_matches(%{state: :q0, dice: 0, finished: false})
        |> GameBoard.action(:start)
        |> pass_if_matches(%{state: :q1, dice: 5, finished: false})

      %{core: res}
    end

    test "game starts with 5 dices", gameboard do
      assert %{state: :q1, dice: 5, finished: false} = gameboard.core
    end

    test "throws dice until they finish", gameboard do
      assert %{state: :q1, dice: 4, finished: false} =
               res1 = GameBoard.action(gameboard.core, :shake)

      assert %{state: :q1, dice: 3, finished: false} = res2 = GameBoard.action(res1, :shake)
      assert %{state: :q1, dice: 2, finished: false} = res3 = GameBoard.action(res2, :shake)
      assert %{state: :q1, dice: 1, finished: false} = res4 = GameBoard.action(res3, :shake)
      assert %{state: :q2, finished: false} = GameBoard.action(res4, :shake)
    end

    test "betting on legs keeps game state", gameboard do
      assert %{state: :q1, finished: false} = GameBoard.action(gameboard.core, {:bet_on_leg, nil})
    end

    test "betting on final winner keeps game state", gameboard do
      assert %{state: :q1, finished: false} =
               GameBoard.action(gameboard.core, {:bet_on_final_winner, :ana, :green})
    end

    test "betting on final looser keeps game state", gameboard do
      assert %{state: :q1, finished: false} =
               GameBoard.action(gameboard.core, {:bet_on_final_winner, :ana, :green})
    end

    test "put trap", gameboard do
      assert %{state: :q1, finished: false} =
               GameBoard.action(gameboard.core, {:put_trap, 10, {:oasis, :ana}})
    end
  end

  describe "From leg finished state" do
    setup do
      res7 = GameBoardCase.warmup_and_start()
      assert %{state: :q1, dice: 4, finished: false} = res8 = GameBoard.action(res7, :shake)
      assert %{state: :q1, dice: 3, finished: false} = res9 = GameBoard.action(res8, :shake)
      assert %{state: :q1, dice: 2, finished: false} = res10 = GameBoard.action(res9, :shake)
      assert %{state: :q1, dice: 1, finished: false} = res11 = GameBoard.action(res10, :shake)
      assert %{state: :q2, finished: false} = res12 = GameBoard.action(res11, :shake)

      %{core: res12}
    end

    test "distributes all money after finishing leg and go back to game", gameboard do
      assert %{state: :q1, dice: 5, finished: false} =
               GameBoard.action(gameboard.core, :got_leg_money)
    end

    test "distribute leg money after last camel crosses and goes to distributing ultimate money" do
      gameboard = %GameBoard{state: :q6}

      assert %{state: :q3} = GameBoard.action(gameboard, :got_leg_money)
    end

    test "distributes ultimate money" do
      gameboard = %GameBoard{finished: true, state: :q3, dice: 0}

      assert %{state: :q4} = res2 = GameBoard.action(gameboard, :got_final_winner_money)
      assert %{state: :q5} = GameBoard.action(res2, :got_final_looser_money)
    end
  end

  describe "Dices balance" do
    setup do
      assert %{state: :q0, dice: 5, finished: false} = res1 = %GameBoard{}
      assert 0 = length(res1.throwndices)
      assert %{state: :q0, dice: 4, finished: false} = res2 = GameBoard.action(res1, :warmup)
      assert 1 = length(res2.throwndices)
      assert %{state: :q0, dice: 3, finished: false} = res3 = GameBoard.action(res2, :warmup)
      assert 2 = length(res3.throwndices)
      assert %{state: :q0, dice: 2, finished: false} = res4 = GameBoard.action(res3, :warmup)
      assert 3 = length(res4.throwndices)
      assert %{state: :q0, dice: 1, finished: false} = res5 = GameBoard.action(res4, :warmup)
      assert 4 = length(res5.throwndices)
      assert %{state: :q0, dice: 0, finished: false} = res6 = GameBoard.action(res5, :warmup)
      assert 5 = length(res6.throwndices)
      assert %{state: :q1, dice: 5, finished: false} = res7 = GameBoard.action(res6, :start)
      assert 0 = length(res7.throwndices)

      %{core: res7}
    end

    test "Throwing five dices is correctly accounted", context do
      assert 0 = length(context.core.throwndices)

      res1 = GameBoard.action(context.core, :shake)
      assert 1 = length(res1.throwndices)

      res2 = GameBoard.action(res1, :shake)
      assert 2 = length(res2.throwndices)

      res3 = GameBoard.action(res2, :shake)
      assert 3 = length(res3.throwndices)

      res4 = GameBoard.action(res3, :shake)
      assert 4 = length(res4.throwndices)

      res5 = GameBoard.action(res4, :shake)
      assert 5 = length(res5.throwndices)
    end
  end

  describe "Betting system" do
    setup do
      res7 = GameBoardCase.warmup_and_start()
      %{core: res7}
    end

    test "Taking bet card removes it from board and check legal entries", context do
      res1 = GameBoard.action(context.core, {:bet_on_leg, :green})
      assert [{:black, 5}, {:blue, 5}, {:green, 3}, {:orange, 5}, {:red, 5}] = res1.bets_avaiable

      res2 = GameBoard.action(res1, {:bet_on_leg, :green})
      assert [{:black, 5}, {:blue, 5}, {:green, 2}, {:orange, 5}, {:red, 5}] = res2.bets_avaiable

      res3 = GameBoard.action(res2, {:bet_on_leg, :green})
      assert [{:black, 5}, {:blue, 5}, {:orange, 5}, {:red, 5}] = res3.bets_avaiable

      res4 = GameBoard.action(res3, {:bet_on_leg, :green})
      assert [{:black, 5}, {:blue, 5}, {:orange, 5}, {:red, 5}] = res4.bets_avaiable

      res5 = GameBoard.action(res3, {:bet_on_leg, :badcolor})
      assert [{:black, 5}, {:blue, 5}, {:orange, 5}, {:red, 5}] = res5.bets_avaiable
    end

    test "After getting leg money, bets supply is restored", context do
      res1 =
        GameBoard.action(context.core, {:bet_on_leg, :green})
        |> GameBoard.action({:bet_on_leg, :green})
        |> GameBoard.action({:bet_on_leg, :blue})
        |> GameBoard.action({:bet_on_leg, :black})
        |> GameBoard.action({:bet_on_leg, :orange})
        |> GameBoard.action({:bet_on_leg, :green})
        |> GameBoard.action(:shake)
        |> GameBoard.action(:shake)
        |> GameBoard.action(:shake)
        |> GameBoard.action(:shake)
        |> GameBoard.action(:shake)
        |> GameBoard.action(:got_leg_money)

      assert res1.bets_avaiable == [{:black, 5}, {:blue, 5}, {:green, 5}, {:orange, 5}, {:red, 5}]
    end
  end

  describe "Desert tiles" do
    setup do
      res = GameBoardCase.warmup_and_start()

      %{game_board: res}
    end

    test "Adding a desert tile", context do
      res =
        context.game_board
        |> GameBoard.action({:put_trap, 10, {:oasis, :ana}})

      assert res.camels |> Enum.member?({10, {:oasis, :ana}})
    end

    test "Tiles position is at most 16", context do
      res =
        context.game_board
        |> GameBoard.action({:put_trap, 26, {:oasis, :ana}})
        |> GameBoard.action({:put_trap, 28, {:oasis, :bob}})

      assert res.camels |> Enum.member?({10, {:oasis, :ana}})
      assert res.camels |> Enum.member?({12, {:oasis, :bob}})
    end

    test "Pos 1 accepts no tiles", context do
      res =
        %{context.game_board | camels: [{3, [:black, :blue, :green, :orange, :red]}]}
        |> GameBoard.action({:put_trap, 1, {:oasis, :ana}})
        |> GameBoard.action({:put_trap, 17, {:oasis, :bob}})

      refute res.camels |> Enum.member?({1, {:oasis, :ana}})
      refute res.camels |> Enum.member?({17, {:oasis, :bob}})
    end

    test "Tiles cannot be adjacent to each other", context do
      # Variation 1
      res =
        %{context.game_board | camels: [{3, [:black, :blue, :green, :orange, :red]}]}
        |> GameBoard.action({:put_trap, 10, {:oasis, :ana}})
        |> GameBoard.action({:put_trap, 9, {:oasis, :bob}})
        |> GameBoard.action({:put_trap, 11, {:oasis, :charlie}})

      refute res.camels |> Enum.member?({9, {:oasis, :bob}})
      refute res.camels |> Enum.member?({11, {:oasis, :charlie}})
      # Variation 2
      res =
        %{context.game_board | camels: [{3, [:black, :blue, :green, :orange, :red]}]}
        |> GameBoard.action({:put_trap, 26, {:oasis, :ana}})
        |> GameBoard.action({:put_trap, 9, {:oasis, :bob}})
        |> GameBoard.action({:put_trap, 11, {:oasis, :charlie}})

      refute res.camels |> Enum.member?({9, {:oasis, :bob}})
      refute res.camels |> Enum.member?({11, {:oasis, :charlie}})
      # Variation 3
      res =
        %{context.game_board | camels: [{3, [:black, :blue, :green, :orange, :red]}]}
        |> GameBoard.action({:put_trap, 10, {:oasis, :ana}})
        |> GameBoard.action({:put_trap, 25, {:oasis, :bob}})
        |> GameBoard.action({:put_trap, 27, {:oasis, :charlie}})

      refute res.camels |> Enum.member?({25, {:oasis, :bob}})
      refute res.camels |> Enum.member?({27, {:oasis, :charlie}})

      # Variation 4
      res =
        %{context.game_board | camels: [{3, [:black, :blue, :green, :orange, :red]}]}
        |> GameBoard.action({:put_trap, 26, {:oasis, :ana}})
        |> GameBoard.action({:put_trap, 25, {:oasis, :bob}})
        |> GameBoard.action({:put_trap, 27, {:oasis, :charlie}})

      refute res.camels |> Enum.member?({25, {:oasis, :bob}})
      refute res.camels |> Enum.member?({27, {:oasis, :charlie}})
    end

    test "Tile cannot overwrite a camel", context do
      res =
        %{context.game_board | camels: [{19, [:black, :blue, :green, :orange, :red]}]}
        |> GameBoard.action({:put_trap, 3, {:oasis, :ana}})
        |> GameBoard.action({:put_trap, 19, {:oasis, :bob}})

      assert res.camels |> Enum.member?({19, [:black, :blue, :green, :orange, :red]})
      refute res.camels |> Enum.member?({3, {:oasis, :ana}})
      refute res.camels |> Enum.member?({3, {:oasis, :bob}})
      refute res.camels |> Enum.member?({19, {:oasis, :bob}})
    end

    test "Cannot put a tile where a camel is", context do
      res =
        %{context.game_board | camels: [{3, [:green]}]}
        |> GameBoard.action({:put_trap, 3, {:oasis, :ana}})
        |> GameBoard.action({:put_trap, 19, {:oasis, :bob}})

      assert res.camels |> Enum.member?({3, [:green]})
      refute res.camels |> Enum.member?({3, {:oasis, :ana}})
      refute res.camels |> Enum.member?({19, {:oasis, :bob}})
    end

    test "Tiles can be adjacent to other camels", context do
      res =
        %{context.game_board | camels: [{3, [:black, :blue, :green, :orange, :red]}]}
        |> GameBoard.action({:put_trap, 4, {:oasis, :ana}})
        |> GameBoard.action({:put_trap, 2, {:mirage, :bob}})

      assert res.camels |> Enum.member?({4, {:oasis, :ana}})
      assert res.camels |> Enum.member?({2, {:mirage, :bob}})
    end

    test "If a char tile is used, setting it moves it instead of replicating", context do
      res =
        %{context.game_board | camels: [{3, [:black, :blue, :green, :orange, :red]}]}
        |> GameBoard.action({:put_trap, 10, {:oasis, :ana}})
        |> GameBoard.action({:put_trap, 12, {:oasis, :ana}})

      assert res.camels |> Enum.member?({12, {:oasis, :ana}})
      refute res.camels |> Enum.member?({10, {:oasis, :ana}})
    end
  end

  describe "Bets on final winner" do
    setup do
      res = GameBoardCase.warmup_and_start()

      %{game_board: res}
    end

    test "Bet get tracked", context do
      res =
        context.game_board
        |> GameBoard.action({:bet_on_final_winner, :green, :ana})
        |> GameBoard.action({:bet_on_final_winner, :blue, :bob})
        |> GameBoard.action({:bet_on_final_winner, :green, :charlie})

      assert [{:green, :ana}, {:blue, :bob}, {:green, :charlie}] = res.final_winner_bets
    end
  end

  describe "Bets on final looser" do
    setup do
      res = GameBoardCase.warmup_and_start()

      %{game_board: res}
    end

    test "Bets get tracked", context do
      res =
        context.game_board
        |> GameBoard.action({:bet_on_final_looser, :green, :ana})
        |> GameBoard.action({:bet_on_final_looser, :blue, :bob})
        |> GameBoard.action({:bet_on_final_looser, :green, :charlie})

      assert [{:green, :ana}, {:blue, :bob}, {:green, :charlie}] = res.final_looser_bets
    end
  end

  describe "States management" do
    test "All transitions until finishing (but excluding it)" do
      %GameBoard{}
      |> forbid_or_allow_actions(%{
        allowonly: [:warmup],
        execute: [:warmup, :warmup, :warmup, :warmup, :warmup]
      })
      |> forbid_or_allow_actions(%{
        allowonly: [:start],
        execute: [:start]
      })
      |> forbid_or_allow_actions(%{
        allowonly: [:shake, :put_trap, :bet_on_leg, :bet_on_final_winner, :bet_on_final_looser],
        execute:
          [:shake] ++
            Enum.take_random(
              [:shake, :put_trap, :bet_on_leg, :bet_on_final_winner, :bet_on_final_looser],
              4
            )
      })
    end

    test "All transitions after finishing" do
      GameBoardCase.shake_to_finish()
      |> forbid_or_allow_actions(%{
        allowonly: [:got_leg_money],
        execute: [:got_leg_money]
      })
      |> forbid_or_allow_actions(%{
        allowonly: [:got_final_winner_money],
        execute: [:got_final_winner_money]
      })
      |> forbid_or_allow_actions(%{
        allowonly: [:got_final_looser_money],
        execute: [:got_final_looser_money]
      })
      |> forbid_or_allow_actions(%{allowonly: []})
    end
  end
end
