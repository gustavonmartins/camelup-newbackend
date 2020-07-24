defmodule CamelUp.GameBoardCase do
  alias CamelUp.GameBoard

  def shake_to_finish() do
    res =
      %GameBoard{}
      |> GameBoard.action(:warmup)
      |> GameBoard.action(:warmup)
      |> GameBoard.action(:warmup)
      |> GameBoard.action(:warmup)
      |> GameBoard.action(:warmup)
      |> GameBoard.action(:start)
      |> GameBoard.action(:shake)
      |> GameBoard.action(:shake)
      |> GameBoard.action(:shake)
      |> GameBoard.action(:shake)
      |> GameBoard.action(:shake)
      |> GameBoard.action(:got_leg_money)
      |> GameBoard.action(:shake)

    %GameBoard{res | camels: [{16, [:black, :blue, :green, :red, :orange]}]}
    |> GameBoard.action(:shake)
  end

  def finish_and_get_leg_money() do
    shake_to_finish()
    |> GameBoard.action(:got_leg_money)
  end

  def warmup_and_start() do
    %GameBoard{}
    |> GameBoard.action(:warmup)
    |> GameBoard.action(:warmup)
    |> GameBoard.action(:warmup)
    |> GameBoard.action(:warmup)
    |> GameBoard.action(:warmup)
    |> GameBoard.action(:start)
  end
end
