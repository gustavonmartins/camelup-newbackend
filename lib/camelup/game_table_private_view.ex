defmodule CamelUp.GameTablePrivateView do
  alias CamelUp.GameTable

  @moduledoc """
  Documentation for Example.
  """

  @derive Jason.Encoder
  defstruct state: nil,
            previousDices: [],
            avaiableLegBets: [],
            circuit: [],
            playerStatuses: [],
            personalItems: []

  @doc ~S"""
  #Example
  iex> 1+1  
  22
  """
  def to_view(%GameTable{} = game_table, char) do
    %CamelUp.GameTablePrivateView{}
    |> Map.put(:state, game_table.game_board.state)
    |> Map.put(
      :previousDices,
      game_table.game_board.throwndices |> Enum.map(fn {color, _val} -> color end)
    )
    |> Map.put(
      :avaiableLegBets,
      game_table.game_board.bets_avaiable
      |> Enum.map(fn {color, value} -> %{"color" => color, "value" => value} end)
    )
    |> Map.put(
      :circuit,
      game_table.game_board.camels
      |> Enum.map(fn {pos, listitems} ->
        %{"position" => Integer.to_string(pos), "items" => Enum.join(listitems, ", ")}
      end)
    )
    |> Map.put(:playerStatuses, game_table |> create_player_statuses())
    |> Map.put(:personalItems, %{
      :tiles => ["Oasis", "Mirage"],
      :finalLegBets => create_player_final_leg_bets(game_table, char)
    })
  end

  defp create_player_statuses(%GameTable{} = game_table) do
    game_table.playing_chars
    |> Enum.map(fn name -> %{:name => name} end)
    |> Enum.map(fn map ->
      currname = map.name
      currmoney = Map.get(game_table.playersmoney, currname)
      Map.put(map, "money", currmoney)
    end)
    |> Enum.map(fn map ->
      currname = map.name

      currbets =
        Map.get(game_table.playersbet, currname)
        |> Enum.map(fn {color, value} ->
          %{:color => color, :value => value}
        end)

      Map.put(map, "bets", currbets)
    end)
  end

  defp create_player_final_leg_bets(%GameTable{} = game_table, player) do
    game_table.finalbets_avaiable
    |> Map.get(player)
  end
end
