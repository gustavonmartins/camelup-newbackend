defmodule CamelupWeb.RoomChannelTest do
  use CamelupWeb.ChannelCase, async: true
  alias CamelupWeb.UserSocket
  alias CamelupWeb.GameChannel

  setup do
    rand_int = :rand.uniform(1_000_000)

    {:ok, _, socket} =
      UserSocket
      |> socket("user_id", %{user_id: 2323})
      |> subscribe_and_join(GameChannel, "games:" <> Integer.to_string(rand_int), %{
        name: "Gustavo"
      })

    %{socket: socket}
  end

  describe "Sending decisions" do
    test "Finishes warmup and do stuff other than throwing dices", %{socket: socket} do
      socket |> push("decision", %{first: "warmup", second: nil, third: nil})
      socket |> push("decision", %{first: "warmup", second: nil, third: nil})
      socket |> push("decision", %{first: "warmup", second: nil, third: nil})
      socket |> push("decision", %{first: "warmup", second: nil, third: nil})
      socket |> push("decision", %{first: "warmup", second: nil, third: nil})
      socket |> push("decision", %{first: "start", second: nil, third: nil})

      assert_broadcast("broadcast_game_table", %CamelUp.GameTablePrivateView{state: :q1})
      socket |> push("decision", %{first: "bet_on_leg", second: "black", third: nil})

      assert_broadcast("broadcast_game_table", %CamelUp.GameTablePrivateView{
        state: :q1,
        avaiableLegBets: [
          %{"color" => :black, "value" => 3},
          %{"color" => :blue, "value" => 5},
          %{"color" => :green, "value" => 5},
          %{"color" => :orange, "value" => 5},
          %{"color" => :red, "value" => 5}
        ]
      })
    end

    test "Bets on leg", %{socket: socket} do
      assert true
    end
  end
end
