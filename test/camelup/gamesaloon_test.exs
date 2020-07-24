defmodule CamelUp.GameSaloonTest do
  use ExUnit.Case, async: true
  alias CamelUp.{GameSaloon, GameTable}
  doctest GameSaloon

  describe "Joining tables on rooms" do
    test "First player joining unexisting table creates it" do
      user = %{uuid: "randomuserid-xyz", char: "Mr. Brown"}

      gs = %GameSaloon{}

      # No player, no room
      assert {:error} = gs |> GameSaloon.get_table_by_id(10)

      # First player on room creates it
      gs = gs |> GameSaloon.be_joined_by_user(user, 10)
      assert {:ok, %GameTable{} = gt} = gs |> GameSaloon.get_table_by_id(10)

      # Checks if first player is really inside its game room
      assert gt |> GameTable.has_char?("Mr. Brown")
      refute gt |> GameTable.has_char?("should-not-be-here")

      # Second player joining doest not reset room
      user2 = %{uuid: "second-user", char: "Mr. Green"}
      gs = gs |> GameSaloon.be_joined_by_user(user2, 10)
      assert {:ok, %GameTable{} = gt} = gs |> GameSaloon.get_table_by_id(10)
      assert gt |> GameTable.has_char?("Mr. Brown")
      assert gt |> GameTable.has_char?("Mr. Green")

      # Second playzer leaving table via saloon is effective
      gs = gs |> GameSaloon.be_left_by_user(user2)

      {:ok, gt} = gs |> GameSaloon.get_table_by_id(10)
      refute gt |> GameTable.has_char?("Mr. Green")
    end

    test "User decisions are sent to correct table" do
      user = %{uuid: "randomuserid-xyz", char: "Mr. Brown"}
      user2 = %{uuid: "randomuserid-2", char: "Mr. Orange"}

      gs =
        %GameSaloon{}
        |> GameSaloon.be_joined_by_user(user, 10)
        |> GameSaloon.be_joined_by_user(user2, 10)

      action = :warmup
      gs = gs |> GameSaloon.user_action(user, action)

      {:ok, gt} = gs |> GameSaloon.get_table_by_id(10)
      assert gt |> GameTable.get_last_char() == "Mr. Brown"
    end

    test "Tables take no more than 8 players" do
    end

    test "Tables disappears if empty" do
    end
  end
end
