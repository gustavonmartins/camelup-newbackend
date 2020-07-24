defmodule CamelUp.GameTable do
  alias CamelUp.{GameTable, GameBoard}

  defstruct currentchar: nil,
            lastchar: nil,
            playing_chars: [],
            game_board: %GameBoard{},
            playersmoney: %{},
            playersbet: %{},
            finalbets_avaiable: %{}

  def privaction(%GameTable{} = game_table, msg) do
    case {msg, game_table} do
      {:getnextchar, %GameTable{} = oldstate} ->
        cond do
          length(oldstate.playing_chars) == 0 ->
            %GameTable{oldstate | currentchar: nil}

          length(oldstate.playing_chars) == 1 ->
            %GameTable{oldstate | currentchar: Enum.at(oldstate.playing_chars, 0)}

          length(oldstate.playing_chars) > 1 ->
            currentchar_pos =
              (Enum.find_index(oldstate.playing_chars, fn x -> x == oldstate.currentchar end) + 1)
              |> rem(length(oldstate.playing_chars))

            %GameTable{
              oldstate
              | currentchar: Enum.at(oldstate.playing_chars, currentchar_pos)
            }
        end
    end
  end

  def action(%GameTable{} = game_table, msg) do
    gt =
      case {msg, game_table} do
        {{:bet_on_leg, betcolor}, %GameTable{}} ->
          bets_avaiable_old = game_table.game_board.bets_avaiable
          char_bets_old = game_table.playersbet[game_table.currentchar]
          gameboard_new = GameBoard.action(game_table.game_board, {:bet_on_leg, betcolor})
          bets_avaiable_new = gameboard_new.bets_avaiable

          char_bets_new = char_bets_old ++ (bets_avaiable_old -- bets_avaiable_new)

          playersbet_new =
            game_table.playersbet
            |> Map.merge(
              %{game_table.currentchar => char_bets_new},
              fn _k, _, v2 ->
                Enum.sort(v2)
              end
            )

          %GameTable{
            game_table
            | game_board: gameboard_new,
              playersbet: playersbet_new
          }
          |> GameTable.privaction(:getnextchar)

        {:get_leg_money, %GameTable{} = game_table} ->
          playersmoney_before = game_table.playersmoney

          playersmoney_delta =
            game_table.playing_chars
            |> Enum.reduce(
              %{},
              fn char, accdelta ->
                Enum.into(
                  accdelta,
                  %{char => calculatecharlegmoney(char, game_table)}
                )
              end
            )

          playersmoney_after =
            playersmoney_before
            |> Map.merge(
              playersmoney_delta,
              fn _char, m1, m2 -> m1 + m2 end
            )

          playersbet_after =
            game_table.playing_chars
            |> Enum.reduce(%{}, fn currplayer, pmap -> pmap |> Enum.into(%{currplayer => []}) end)

          %GameTable{
            game_table
            | playersmoney: playersmoney_after,
              game_board: GameBoard.action(game_table.game_board, :got_leg_money),
              playersbet: playersbet_after
          }

        {{:put_trap, type, pos}, %GameTable{} = game_table} ->
          %GameTable{
            game_table
            | game_board:
                GameBoard.action(
                  game_table.game_board,
                  {:put_trap, pos, {type, game_table.currentchar}}
                )
          }
          |> GameTable.privaction(:getnextchar)

        {:shake, %GameTable{}} ->
          gb = GameBoard.action(game_table.game_board, msg)

          playersmoney_beforetile = %{
            game_table.playersmoney
            | game_table.currentchar =>
                game_table.playersmoney[game_table.currentchar] -
                  (gb.dice - game_table.game_board.dice)
          }

          tilemoney =
            case gb.current_tile_bonus do
              nil ->
                %{}

              char ->
                %{char => 1}
            end

          playersmoney =
            playersmoney_beforetile |> Map.merge(tilemoney, fn _k, v1, v2 -> v1 + v2 end)

          %GameTable{game_table | game_board: gb, playersmoney: playersmoney}
          |> GameTable.privaction(:getnextchar)

        {{:bet_on_final_winner, color}, %GameTable{}} ->
          bet_on_finals(game_table, :winner, color)

        {{:bet_on_final_looser, color}, %GameTable{}} ->
          bet_on_finals(game_table, :looser, color)

        {:get_final_winner_money, %GameTable{}} ->
          calculatefinallegsmoney(:winner, game_table)

        {:get_final_looser_money, %GameTable{}} ->
          calculatefinallegsmoney(:looser, game_table)

        {msg, %GameTable{}} ->
          gb = GameBoard.action(game_table.game_board, msg)

          if Enum.member?([:warmup, :start, :got_leg_money], msg) do
            %GameTable{game_table | game_board: gb}
          end
      end

    gt |> recognize_last_char(game_table.currentchar)
  end

  def get_last_char(%GameTable{} = gt) do
    gt.lastchar
  end

  def addchar(%GameTable{} = game_table, char) do
    base = %GameTable{
      game_table
      | playing_chars: game_table.playing_chars ++ [char],
        playersmoney: Enum.into(game_table.playersmoney, %{char => 0}),
        playersbet: Enum.into(game_table.playersbet, %{char => []}),
        finalbets_avaiable:
          Enum.into(game_table.finalbets_avaiable, %{
            char => [:black, :blue, :green, :orange, :red]
          })
    }

    if length(base.playing_chars) == 1 do
      %GameTable{base | currentchar: char}
    else
      base
    end
  end

  def removechar(%GameTable{} = game_table, char) do
    base_gt = %GameTable{
      game_table
      | playing_chars: game_table.playing_chars -- [char],
        playersmoney: game_table.playersmoney |> Map.delete(char),
        playersbet: game_table.playersbet |> Map.delete(char),
        finalbets_avaiable: game_table.finalbets_avaiable |> Map.delete(char)
    }

    case base_gt.currentchar do
      ^char -> base_gt |> privaction(:getnextchar)
      _ -> base_gt
    end
  end

  defp calculatecharlegmoney(currchar, %GameTable{} = gt) do
    gt.playersbet[currchar]
    |> Enum.map(fn {color, val} ->
      cond do
        GameBoard.get_first_camel(gt.game_board.camels) == color ->
          val

        GameBoard.get_second_camel(gt.game_board.camels) == color ->
          1

        true ->
          -1
      end
    end)
    |> Enum.sum()
  end

  defp bet_on_finals(%GameTable{} = game_table, type, color) do
    gb =
      case Enum.member?(game_table.finalbets_avaiable[game_table.currentchar], color) do
        false ->
          game_table.game_board

        _ ->
          case type do
            :winner ->
              game_table.game_board
              |> GameBoard.action({:bet_on_final_winner, color, game_table.currentchar})

            :looser ->
              game_table.game_board
              |> GameBoard.action({:bet_on_final_looser, color, game_table.currentchar})
          end
      end

    fba =
      game_table.finalbets_avaiable
      |> Map.merge(
        %{
          game_table.currentchar =>
            game_table.finalbets_avaiable[game_table.currentchar] -- [color]
        },
        fn _k, _v1, v2 -> v2 end
      )

    %GameTable{game_table | game_board: gb, finalbets_avaiable: fba}
    |> GameTable.privaction(:getnextchar)
  end

  defp calculatefinallegsmoney(type, %GameTable{} = game_table) do
    {betslist, posfun} =
      case type do
        :winner ->
          {game_table.game_board.final_winner_bets, &GameBoard.get_first_camel/1}

        :looser ->
          {game_table.game_board.final_looser_bets, &GameBoard.get_last_camel/1}
      end

    pm =
      betslist
      |> Enum.reduce(
        {%{}, 8},
        fn {color, char}, {acc, points} ->
          cond do
            color != posfun.(game_table.game_board.camels) ->
              {acc |> Enum.into(%{char => -1}), points}

            color == posfun.(game_table.game_board.camels) ->
              case points do
                8 ->
                  {acc |> Enum.into(%{char => points}), 5}

                5 ->
                  {acc |> Enum.into(%{char => points}), 3}

                3 ->
                  {acc |> Enum.into(%{char => points}), 2}

                2 ->
                  {acc |> Enum.into(%{char => points}), 1}

                1 ->
                  {acc |> Enum.into(%{char => points}), 1}
              end
          end
        end
      )
      |> elem(0)
      |> Map.merge(game_table.playersmoney, fn _k, v1, v2 -> v1 + v2 end)

    %GameTable{game_table | playersmoney: pm}
  end

  def new do
    %GameTable{}
  end

  def has_char?(%GameTable{} = gt, char) do
    gt.playing_chars |> Enum.member?(char)
  end

  defp recognize_last_char(%GameTable{} = gt, char) do
    %GameTable{gt | lastchar: char}
  end
end

defmodule CamelUp.GameTablePrivateView do
  alias CamelUp.GameTable

  @derive Jason.Encoder
  defstruct state: nil,
            previousDices: [],
            avaiableLegBets: [],
            circuit: [],
            playerStatuses: [],
            personalItems: []

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
