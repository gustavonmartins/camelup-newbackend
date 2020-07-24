defmodule CamelUp.GameTableCase do
  alias CamelUp.GameTable

  def middle_of_game() do
    %GameTable{}
    |> GameTable.addchar(:ana)
    |> GameTable.addchar(:bob)
    |> GameTable.addchar(:charlie)
    |> GameTable.action(:warmup)
    |> GameTable.action(:warmup)
    |> GameTable.action(:warmup)
    |> GameTable.action(:warmup)
    |> GameTable.action(:warmup)
    |> GameTable.action(:start)
    |> GameTable.action(:shake)
    |> GameTable.action(:shake)
    |> GameTable.action(:shake)
    |> GameTable.action({:bet_on_leg, :green})
    |> GameTable.action({:bet_on_leg, :green})
    |> GameTable.action({:put_trap, :mirage, 5})
    |> GameTable.action(:shake)
    |> GameTable.action(:shake)
    |> GameTable.action(:get_leg_money)
    |> GameTable.action(:shake)
    |> GameTable.action({:bet_on_leg, :black})
    |> GameTable.action({:put_trap, :mirage, 5})
    |> GameTable.action({:bet_on_leg, :green})
    |> GameTable.action({:bet_on_final_winner, :orange})
    |> GameTable.action({:bet_on_final_looser, :blue})
    |> GameTable.action(:shake)
  end

  def middle_of_game_deterministic() do
    %CamelUp.GameTable{
      currentchar: :ana,
      finalbets_avaiable: %{
        ana: [:black, :blue, :green, :red],
        bob: [:black, :green, :orange, :red],
        charlie: [:black, :blue, :green, :orange, :red]
      },
      game_board: %CamelUp.GameBoard{
        bets_avaiable: [black: 3, blue: 5, green: 3, orange: 5, red: 5],
        camels: [{9, [:green]}, {7, [:black]}, {5, [:orange, :red]}, {2, [:blue]}],
        current_tile_bonus: nil,
        dice: 3,
        final_looser_bets: [blue: :bob],
        final_winner_bets: [orange: :ana],
        finished: false,
        state: :q1,
        throwndices: [green: 2, black: 3]
      },
      playersbet: %{ana: [black: 5], bob: [], charlie: [green: 5]},
      playersmoney: %{ana: 1, bob: 1, charlie: 3},
      playing_chars: [:ana, :bob, :charlie]
    }
  end
end
