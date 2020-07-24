defmodule CamelUp.GameBoard do
  @moduledoc """
  Documentation for Example.
  """

  defstruct state: :q0,
            dice: 5,
            finished: false,
            camels: [{0, [:black, :blue, :green, :orange, :red]}],
            throwndices: [],
            bets_avaiable: [{:black, 5}, {:blue, 5}, {:green, 5}, {:orange, 5}, {:red, 5}],
            current_tile_bonus: nil,
            final_winner_bets: [],
            final_looser_bets: []

  alias CamelUp.GameBoard

  def action(%GameBoard{} = game_board, msg) do
    case {msg, game_board} do
      {:warmup, %GameBoard{state: :q0, dice: dice, finished: false} = oldstate} ->
        cond do
          dice >= 1 ->
            throwndices = calc_throwndices(game_board)

            # This is incomplete and will fail when a dice is moved again. Tests will catch it soon!

            %GameBoard{
              oldstate
              | throwndices: throwndices,
                dice: 5 - length(throwndices),
                camels: calc_pos_onedice(game_board.camels, List.first(throwndices)) |> elem(0)
            }
        end

      {:start, %GameBoard{state: :q0, dice: 0, finished: false} = oldstate} ->
        %GameBoard{oldstate | throwndices: [], dice: 5, state: :q1}

      {:shake, %GameBoard{state: :q1, dice: dice}} ->
        throwndices = calc_throwndices(game_board)

        {camels, current_tile_bonus} =
          calc_pos_onedice(game_board.camels, List.first(throwndices))

        # Calculates next state
        nextstate =
          cond do
            is_finished(camels) ->
              :q6

            dice > 1 ->
              :q1

            dice == 1 ->
              :q2
          end

        # Adds up information
        %GameBoard{
          game_board
          | throwndices: throwndices,
            state: nextstate,
            dice: 5 - length(throwndices),
            camels: camels,
            current_tile_bonus: current_tile_bonus,
            finished: is_finished(camels)
        }

      {{:bet_on_leg, choosen_color}, %GameBoard{state: :q1, finished: false}} ->
        case Enum.find_index(game_board.bets_avaiable, fn {cand_color, _} ->
               cand_color == choosen_color
             end) do
          nil ->
            game_board

          pos ->
            {effective_color, effective_val} = Enum.at(game_board.bets_avaiable, pos)

            cond do
              effective_val == 5 ->
                new_bets =
                  game_board.bets_avaiable
                  |> List.replace_at(pos, {effective_color, 3})

                %GameBoard{game_board | bets_avaiable: new_bets}

              effective_val == 3 ->
                new_bets =
                  game_board.bets_avaiable
                  |> List.replace_at(pos, {effective_color, 2})

                %GameBoard{game_board | bets_avaiable: new_bets}

              effective_val == 2 ->
                new_bets =
                  game_board.bets_avaiable
                  |> List.delete_at(pos)

                %GameBoard{game_board | bets_avaiable: new_bets}
            end
        end

      {{:bet_on_final_winner, color, char}, %GameBoard{state: :q1} = oldstate} ->
        final_winner_bets_old = oldstate.final_winner_bets

        %GameBoard{oldstate | final_winner_bets: final_winner_bets_old ++ [{color, char}]}

      {{:bet_on_final_looser, color, char}, %GameBoard{state: :q1} = oldstate} ->
        final_looser_bets_old = oldstate.final_looser_bets

        %GameBoard{oldstate | final_looser_bets: final_looser_bets_old ++ [{color, char}]}

      {{:put_trap, pos, tile}, %GameBoard{state: :q1} = oldstate} ->
        pos = rem(pos, 16)

        newcamels =
          cond do
            # Cannot occupy first position
            1 == rem(pos, 16) ->
              oldstate.camels

            # Used positions are invalid
            # Adjacent tiles invalid
            nil ==
                Enum.find(oldstate.camels, fn {currpos, _} -> rem(currpos, 16) == rem(pos, 16) end) ->
              cond do
                Enum.find(
                  oldstate.camels,
                  fn {currpos, curritem} ->
                    rem(currpos, 16) == rem(pos + 1, 16) and
                        is_tuple(curritem)
                  end
                ) ->
                  oldstate.camels

                Enum.find(
                  oldstate.camels,
                  fn {currpos, curritem} ->
                    rem(currpos, 16) == rem(pos - 1, 16) and
                        is_tuple(curritem)
                  end
                ) ->
                  oldstate.camels

                true ->
                  oldstate.camels ++ [{pos, tile}]
              end

            true ->
              oldstate.camels
          end

        newcamels =
          case Enum.find_index(
                 oldstate.camels,
                 fn {_, tileorcamels} ->
                   case tileorcamels do
                     {_, currchar} ->
                       currchar == elem(tile, 1)

                     [_camel | _othercamels] ->
                       false
                   end
                 end
               ) do
            nil ->
              newcamels

            index ->
              newcamels |> List.delete_at(index)
          end

        %GameBoard{oldstate | camels: newcamels |> Enum.sort() |> Enum.reverse()}

      {:got_leg_money, %GameBoard{state: :q2} = oldstate} ->
        throwndices = []

        %{
          oldstate
          | state: :q1,
            dice: 5 - length(throwndices),
            throwndices: [],
            bets_avaiable: %GameBoard{}.bets_avaiable
        }

      {:got_leg_money, %GameBoard{state: :q6} = oldstate} ->
        %{
          oldstate
          | state: :q3,
            dice: nil,
            throwndices: nil,
            bets_avaiable: nil
        }

      {:got_final_winner_money, %GameBoard{state: :q3} = oldstate} ->
        %{oldstate | state: :q4}

      {:got_final_looser_money, %GameBoard{state: :q4} = oldstate} ->
        %{oldstate | state: :q5}
    end
  end

  defp calc_throwndices(%GameBoard{} = game_board) do
    # Throws dice
    throwndices_before_colorsonly =
      game_board.throwndices
      |> Enum.map(fn {x, _} -> x end)

    [
      {Enum.random([:red, :green, :orange, :blue, :black] -- throwndices_before_colorsonly),
       :rand.uniform(3)}
      | game_board.throwndices
    ]
  end

  @doc """


  ## Examples

      iex> GameBoard.calc_pos_onedice([{3,[:green]}], {:green, 3})
      {[{6,[:green]}], nil}

      iex> GameBoard.calc_pos_onedice([{6,{:oasis,:ana}},{3,[:green]}], {:green, 3})
      {[{7,[:green]},{6,{:oasis,:ana}}], :ana}

      iex> GameBoard.calc_pos_onedice([{6,{:mirage,:bob}},{3,[:green]}], {:green, 3})
      {[{6,{:mirage,:bob}},{5,[:green]}], :bob}

      iex> GameBoard.calc_pos_onedice([{7,[:black,:blue]},{6,{:oasis,:charlie}},{3,[:green]}], {:green, 3})
      {[{7,[:green,:black,:blue]},{6,{:oasis,:charlie}}], :charlie}

      iex> GameBoard.calc_pos_onedice([{6,{:mirage,:david}},{5,[:black,:blue]},{3,[:green]}], {:green, 3})
      {[{6,{:mirage,:david}},{5,[:black,:blue,:green]}], :david}

      iex> GameBoard.calc_pos_onedice([{6,{:mirage,:edward}},{5,[:black,:blue]},{3,[:green,:orange]}], {:green, 3})
      {[{6,{:mirage,:edward}},{5,[:black,:blue,:green]},{3,[:orange]}], :edward}

      iex> GameBoard.calc_pos_onedice([{6,{:mirage,:frank}},{5,[:black,:blue]},{3,[:green,:orange]}], {:orange, 3})
      {[{6,{:mirage,:frank}},{5,[:black,:blue,:green,:orange]}], :frank}

      iex> GameBoard.calc_pos_onedice([{6,{:oasis,:greg}},{21,[:black,:blue]},{19,[:green,:orange]}], {:orange, 3})
      {[{23,[:green,:orange]},{21,[:black,:blue]},{6,{:oasis,:greg}}], :greg}

      iex> GameBoard.calc_pos_onedice([{6,{:mirage,:harry}},{21,[:black,:blue]},{19,[:green,:orange]}], {:orange, 3})
      {[{21,[:black,:blue,:green,:orange]},{6,{:mirage,:harry}}], :harry}

      iex> GameBoard.calc_pos_onedice([{6, {:mirage, :sarra}},{5, [:black]},{4, {:mirage, :gustavo}},{3, [:orange, :blue]}],{:orange, 1})
      {[{6, {:mirage, :sarra}},{5, [:black]},{4, {:mirage, :gustavo}},{3, [:blue,:orange]}],:gustavo}

      iex> GameBoard.calc_pos_onedice([{6, {:mirage, :sarra}},{5, [:red, :black]}],{:red, 1})
      {[{6, {:mirage, :sarra}},{5, [:black, :red]}],:sarra}

      iex> GameBoard.calc_pos_onedice([{6, {:mirage, :sarra}},{5, [:gray, :red, :black]}],{:red, 1})
      {[{6, {:mirage, :sarra}},{5, [:black,:gray, :red]}],:sarra}


  """
  def calc_pos_onedice(camels, {dcolor, dval}) do
    decompressed_base = List.duplicate([], 31)

    decompressed_camels =
      List.foldl(
        camels,
        decompressed_base,
        fn {pos, camels}, acc ->
          List.replace_at(acc, pos, camels)
        end
      )

    # |> IO.inspect(label: "decompressed_camels")

    move_from_pos =
      decompressed_camels
      |> Enum.find_index(fn clist ->
        cond do
          is_tuple(clist) ->
            false

          is_list(clist) ->
            clist |> Enum.member?(dcolor)
        end
      end)

    # |> IO.inspect(label: "move_from_pos")

    move_from_pos_content = Enum.at(decompressed_camels, move_from_pos)

    {camels_to_move, _} =
      decompressed_camels
      |> Enum.at(move_from_pos)
      |> (fn camels ->
            if move_from_pos != 0 do
              camels
              |> Enum.split(
                Enum.find_index(move_from_pos_content, fn color -> color == dcolor end) + 1
              )
            else
              {[dcolor], nil}
            end
          end).()

    # |> IO.inspect(label: "camels_to_move")

    # camels_to_stay |> IO.inspect(label: "camels_to_stay")

    move_to_pos_base = move_from_pos + dval

    posonlist =
      Enum.find_index(
        camels,
        fn {currpos, _content} -> rem(currpos, 16) == rem(move_to_pos_base, 16) end
      )

    {correction, coinforchar} =
      cond do
        is_nil(posonlist) ->
          {0, nil}

        true ->
          case Enum.at(camels, posonlist) do
            {_pos, {:oasis, char}} ->
              {1, char}

            {_pos, {:mirage, char}} ->
              {-1, char}

            _ ->
              {0, nil}
          end
      end

    move_to_pos = move_to_pos_base + correction

    decompressed_camels =
      decompressed_camels
      |> List.replace_at(
        move_from_pos,
        Enum.at(decompressed_camels, move_from_pos) -- camels_to_move
      )
      |> List.replace_at(
        move_to_pos,
        cond do
          correction >= 0 ->
            camels_to_move ++ Enum.at(decompressed_camels, move_to_pos)

          correction < 0 ->
            (Enum.at(decompressed_camels, move_to_pos) -- camels_to_move) ++ camels_to_move
        end
      )

    # |> IO.inspect(label: "decompressed_camels")

    # compressed_camels=Enum.reduce( [], fun pos,acc -> if pos != [] do  end end)
    compressed_camels =
      Enum.reduce(
        0..30,
        [],
        fn pos, acc ->
          [{pos, Enum.at(decompressed_camels, pos)}] ++ acc
        end
      )
      |> Enum.reduce([], fn {pos, clist}, acc ->
        if clist != [] do
          acc ++ [{pos, clist}]
        else
          acc
        end
      end)

    {compressed_camels, coinforchar}
  end

  @doc """
      iex> GameBoard.get_first_camel([{17,[:green]}, {15, [:blue]},{13,[:red,:orange]}])
      :green

      iex> GameBoard.get_first_camel([{17, [:red, :orange, :green, :blue, :black]}])
      :red

      iex> GameBoard.get_first_camel([{18,{:mirage,:bob}},{17,[:green]}, {15, [:blue]},{14,{:mirage, :ana}},{13,[:red,:orange]},{12,{:mirage,:bob}}])
      :green
  """
  def get_first_camel(camels) when is_list(camels) do
    [chead | ctail] = camels

    case chead do
      {_pos, {_tiletype, _tilechar}} ->
        get_first_camel(ctail)

      {_pos, [firstcamel | _othercamels]} ->
        firstcamel
    end
  end

  def get_second_camel(camels) when is_list(camels) do
    [chead | ctail] = camels

    case chead do
      {_pos, {_tiletype, _tilechar}} ->
        get_second_camel(ctail)

      {_pos, [_firstcamel | othercamels]} when othercamels != [] ->
        hd(othercamels)

      {_pos, [_firstcamel | []]} ->
        get_first_camel(ctail)
    end
  end

  @doc """
  ## Examples
      iex> GameBoard.get_last_camel([{17,[:green]}, {15, [:blue]},{13,[:red,:orange]}])
      :orange

      iex> GameBoard.get_last_camel([{17, [:red, :orange, :green, :blue, :black]}])
      :black

      iex> GameBoard.get_last_camel([{17,[:green]}, {15, [:blue]},{14,{:mirage, :ana}},{13,[:red,:orange]},{12,{:mirage,:bob}}])
      :orange
  """
  def get_last_camel(camels) when is_list(camels) do
    camels
    |> Enum.reverse()
    |> Enum.map(fn {pos, item} ->
      case item do
        camels when is_list(camels) ->
          {pos, camels |> Enum.reverse()}

        _ ->
          {pos, item}
      end
    end)
    |> get_first_camel()
  end

  defp is_finished(camels) do
    camels
    |> Enum.find(fn {pos, item} ->
      pos > 16 and is_list(item)
    end) !=
      nil
  end
end
