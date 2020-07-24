defmodule Camelup.GameTableTest do
  use ExUnit.Case, async: true
  alias CamelUp.{GameTable, GameTableCase, GameTablePrivateView}
  doctest GameTable

  describe "See if round robbin works" do
    setup do
      gametable =
        %GameTable{}
        |> GameTable.addchar(:char1)
        |> GameTable.addchar(:char2)
        |> GameTable.addchar(:char3)
        |> GameTable.addchar(:char4)
        |> GameTable.addchar(:char5)

      %{gametable: gametable}
    end

    test "See if quantity of added chars matches", context do
      res1 = context.gametable
      assert length(res1.playing_chars) == 5
    end

    test "See if round robbin works", context do
      assert %{currentchar: :char1} = res1 = context.gametable
      assert %{currentchar: :char2} = res2 = GameTable.privaction(res1, :getnextchar)
      assert %{currentchar: :char3} = res3 = GameTable.privaction(res2, :getnextchar)
      assert %{currentchar: :char4} = res4 = GameTable.privaction(res3, :getnextchar)
      assert %{currentchar: :char5} = res5 = GameTable.privaction(res4, :getnextchar)
      assert %{currentchar: :char1} = res6 = GameTable.privaction(res5, :getnextchar)
      assert %{currentchar: :char2} = res7 = GameTable.privaction(res6, :getnextchar)
      assert %{currentchar: :char3} = GameTable.privaction(res7, :getnextchar)
    end

    test "First added player is first to play" do
      gametable =
        %GameTable{}
        |> GameTable.addchar(:char1)

      assert %{currentchar: :char1} = gametable
    end

    test ", on all game actions", context do
      assert %{currentchar: :char1} = res1 = context.gametable
      assert %{currentchar: :char1} = res2 = GameTable.action(res1, :warmup)
      assert %{currentchar: :char1} = res3 = GameTable.action(res2, :warmup)
      assert %{currentchar: :char1} = res4 = GameTable.action(res3, :warmup)
      assert %{currentchar: :char1} = res5 = GameTable.action(res4, :warmup)
      assert %{currentchar: :char1} = res6 = GameTable.action(res5, :warmup)
      assert %{currentchar: :char1} = res7 = GameTable.action(res6, :start)
      assert %{currentchar: :char2} = res8 = GameTable.action(res7, :shake)
      assert %{currentchar: :char3} = res9 = GameTable.action(res8, {:put_trap, :oasis, 10})
      assert %{currentchar: :char4} = GameTable.action(res9, {:bet_on_final_winner, :green})
    end
  end

  describe "Shaking money is distributed correctly" do
    setup do
      gametable =
        %GameTable{}
        |> GameTable.addchar(:ana)
        |> GameTable.addchar(:bob)
        |> GameTable.addchar(:charlie)
        |> GameTable.addchar(:david)
        |> GameTable.addchar(:edward)

      %{gametable: gametable}
    end

    test "Players start with no money", context do
      assert %{playersmoney: %{ana: 0, bob: 0, charlie: 0, david: 0, edward: 0}} =
               context.gametable
    end

    test "Warming up generates no money", context do
      assert %{playersmoney: %{ana: 0, bob: 0, charlie: 0, david: 0, edward: 0}} =
               res1 = GameTable.action(context.gametable, :warmup)

      assert %{playersmoney: %{ana: 0, bob: 0, charlie: 0, david: 0, edward: 0}} =
               res2 = GameTable.action(res1, :warmup)

      assert %{playersmoney: %{ana: 0, bob: 0, charlie: 0, david: 0, edward: 0}} =
               res3 = GameTable.action(res2, :warmup)

      assert %{playersmoney: %{ana: 0, bob: 0, charlie: 0, david: 0, edward: 0}} =
               res4 = GameTable.action(res3, :warmup)

      assert %{playersmoney: %{ana: 0, bob: 0, charlie: 0, david: 0, edward: 0}} =
               res5 = GameTable.action(res4, :warmup)

      assert %{playersmoney: %{ana: 0, bob: 0, charlie: 0, david: 0, edward: 0}} =
               GameTable.action(res5, :start)
    end
  end

  describe "During warm up" do
  end

  describe "After warm up" do
    setup do
      res =
        %GameTable{}
        |> GameTable.addchar(:ana)
        |> GameTable.addchar(:bob)
        |> GameTable.addchar(:charlie)
        |> GameTable.addchar(:david)
        |> GameTable.addchar(:edward)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:start)

      %{gametable: res}
    end

    test "After playing, next character is selected. Warmup doesnt change player", context do
      assert %{currentchar: :ana} = res1 = context.gametable
      assert %{currentchar: :bob} = res2 = GameTable.action(res1, :shake)
      assert %{currentchar: :charlie} = res3 = GameTable.action(res2, :shake)
      assert %{currentchar: :david} = res4 = GameTable.action(res3, :shake)
      assert %{currentchar: :edward} = res5 = GameTable.action(res4, :shake)
      assert %{currentchar: :ana} = res6 = GameTable.action(res5, {:bet_on_leg, nil})
      assert %{currentchar: :bob} = GameTable.action(res6, :shake)
    end

    test "Each player gets 1 money for throwing a dice, except who doesnt throw", context do
      assert %{playersmoney: %{ana: 0, bob: 0, charlie: 0, david: 0, edward: 0}} =
               res1 = context.gametable

      # ana
      assert %{playersmoney: %{ana: 1, bob: 0, charlie: 0, david: 0, edward: 0}} =
               res2 = GameTable.action(res1, :shake)

      # bob
      assert %{playersmoney: %{ana: 1, bob: 0, charlie: 0, david: 0, edward: 0}} =
               res3 = GameTable.action(res2, {:put_trap, :oasis, 10})

      # charlie
      assert %{playersmoney: %{ana: 1, bob: 0, charlie: 0, david: 0, edward: 0}} =
               res4 = GameTable.action(res3, {:put_trap, :oasis, 12})

      assert %{playersmoney: %{ana: 1, bob: 0, charlie: 0, david: 1, edward: 0}} =
               res5 = GameTable.action(res4, :shake)

      assert %{playersmoney: %{ana: 1, bob: 0, charlie: 0, david: 1, edward: 0}} =
               res6 = GameTable.action(res5, {:bet_on_leg, nil})

      assert %{playersmoney: %{ana: 2, bob: 0, charlie: 0, david: 1, edward: 0}} =
               res7 = GameTable.action(res6, :shake)

      assert %{playersmoney: %{ana: 2, bob: 1, charlie: 0, david: 1, edward: 0}} =
               res8 = GameTable.action(res7, :shake)

      assert %{playersmoney: %{ana: 2, bob: 1, charlie: 1, david: 1, edward: 0}} =
               GameTable.action(res8, :shake)
    end
  end

  describe "Right before entering state :q2, when small round is finished" do
    setup do
      res =
        %GameTable{}
        |> GameTable.addchar(:ana)
        |> GameTable.addchar(:bob)
        |> GameTable.addchar(:charlie)
        |> GameTable.addchar(:david)
        |> GameTable.addchar(:edward)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:start)
        |> GameTable.action(:shake)
        |> GameTable.action(:shake)
        |> GameTable.action(:shake)
        |> GameTable.action(:shake)
        |> GameTable.action(:shake)

      %{gametable: res}
    end

    test "Getting leg money cannot decrease anoybodies money", context do
      gt_before = context.gametable
      gt_after = GameTable.action(gt_before, :got_leg_money)

      assert gt_after.playersmoney.ana >= gt_before.playersmoney.bob
      assert gt_after.playersmoney.bob >= gt_before.playersmoney.bob
      assert gt_after.playersmoney.charlie >= gt_before.playersmoney.charlie
      assert gt_after.playersmoney.david >= gt_before.playersmoney.david
      assert gt_after.playersmoney.edward >= gt_before.playersmoney.edward
    end

    test "Getting leg money restores amount of throwndices to 0", context do
      assert 0 =
               length(GameTable.action(context.gametable, :got_leg_money).game_board.throwndices)
    end
  end

  describe "Betting system" do
    setup do
      res =
        %GameTable{}
        |> GameTable.addchar(:ana)
        |> GameTable.addchar(:bob)
        |> GameTable.addchar(:charlie)
        |> GameTable.addchar(:david)
        |> GameTable.addchar(:edward)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:start)

      %{gametable: res}
    end

    test "Betting gets tracked", context do
      res1 = context.gametable |> GameTable.action({:bet_on_leg, :green})
      assert %{:ana => [{:green, 5}]} = res1.playersbet

      res2 = res1 |> GameTable.action({:bet_on_leg, :green})
      assert %{:ana => [{:green, 5}], :bob => [{:green, 3}]} = res2.playersbet

      res3 = res2 |> GameTable.action({:bet_on_leg, :green})

      assert %{:ana => [{:green, 5}], :bob => [{:green, 3}], :charlie => [{:green, 2}]} =
               res3.playersbet

      res4 = res3 |> GameTable.action({:bet_on_leg, :black})

      assert %{
               :ana => [{:green, 5}],
               :bob => [{:green, 3}],
               :charlie => [{:green, 2}],
               :david => [{:black, 5}]
             } = res4.playersbet

      res5 = res4 |> GameTable.action({:bet_on_leg, :black})

      assert %{
               :ana => [{:green, 5}],
               :bob => [{:green, 3}],
               :charlie => [{:green, 2}],
               :david => [{:black, 5}],
               :edward => [{:black, 3}]
             } = res5.playersbet

      res6 = res5 |> GameTable.action({:bet_on_leg, :black})

      assert %{
               :ana => [{:black, 2}, {:green, 5}],
               :bob => [{:green, 3}],
               :charlie => [{:green, 2}],
               :david => [{:black, 5}],
               :edward => [{:black, 3}]
             } = res6.playersbet

      res7 = res6 |> GameTable.action({:bet_on_leg, :blue})

      assert %{
               :ana => [{:black, 2}, {:green, 5}],
               :bob => [{:blue, 5}, {:green, 3}],
               :charlie => [{:green, 2}],
               :david => [{:black, 5}],
               :edward => [{:black, 3}]
             } = res7.playersbet

      res8 = res7 |> GameTable.action({:bet_on_leg, :orange})

      assert %{
               :ana => [{:black, 2}, {:green, 5}],
               :bob => [{:blue, 5}, {:green, 3}],
               :charlie => [{:green, 2}, {:orange, 5}],
               :david => [{:black, 5}],
               :edward => [{:black, 3}]
             } = res8.playersbet

      res9 = res8 |> GameTable.action({:bet_on_leg, :red})

      assert %{
               :ana => [{:black, 2}, {:green, 5}],
               :bob => [{:blue, 5}, {:green, 3}],
               :charlie => [{:green, 2}, {:orange, 5}],
               :david => [{:black, 5}, {:red, 5}],
               :edward => [{:black, 3}]
             } = res9.playersbet

      res10 = res9 |> GameTable.action({:bet_on_leg, :red})

      assert %{
               :ana => [{:black, 2}, {:green, 5}],
               :bob => [{:blue, 5}, {:green, 3}],
               :charlie => [{:green, 2}, {:orange, 5}],
               :david => [{:black, 5}, {:red, 5}],
               :edward => [{:black, 3}, {:red, 3}]
             } = res10.playersbet

      res11 = res10 |> GameTable.action({:bet_on_leg, :red})

      assert %{
               :ana => [{:black, 2}, {:green, 5}, {:red, 2}],
               :bob => [{:blue, 5}, {:green, 3}],
               :charlie => [{:green, 2}, {:orange, 5}],
               :david => [{:black, 5}, {:red, 5}],
               :edward => [{:black, 3}, {:red, 3}]
             } = res11.playersbet
    end

    test "Bets once on first place correctly", context do
      gt1 =
        GameTable.action(context.gametable, {:bet_on_leg, :black})
        |> GameTable.action(:shake)
        |> GameTable.action(:shake)
        |> GameTable.action(:shake)
        |> GameTable.action(:shake)
        |> GameTable.action(:shake)

      gt1 = %GameTable{
        gt1
        | game_board: %{
            gt1.game_board
            | camels: [{1, [:black]}, {0, [:blue, :green, :orange, :red]}]
          }
      }

      %{playersmoney: %{ana: ana_before}} = gt1
      %{playersmoney: %{ana: ana_after}} = GameTable.action(gt1, :get_leg_money)
      assert ana_after == ana_before + 5
    end

    test "Bets twice on first place correctly", context do
      # ana
      gt1 =
        GameTable.action(context.gametable, {:bet_on_leg, :black})
        # bob blue 5
        |> GameTable.action({:bet_on_leg, :blue})
        # charlie
        |> GameTable.action(:shake)
        # david
        |> GameTable.action(:shake)
        # edward
        |> GameTable.action(:shake)
        # ana
        |> GameTable.action({:bet_on_leg, :black})
        # bob black 2
        |> GameTable.action({:bet_on_leg, :black})
        # charlie
        |> GameTable.action(:shake)
        # david
        |> GameTable.action(:shake)

      gt1 = %GameTable{
        gt1
        | game_board: %{
            gt1.game_board
            | camels: [{3, [:black]}, {2, [:blue]}, {1, [:green, :orange, :red]}]
          }
      }

      %{
        playersmoney: %{
          ana: ana_before,
          bob: bob_before,
          charlie: charlie_before,
          david: david_before,
          edward: edward_before
        }
      } = gt1

      %{
        playersmoney: %{
          ana: ana_after,
          bob: bob_after,
          charlie: charlie_after,
          david: david_after,
          edward: edward_after
        }
      } = GameTable.action(gt1, :get_leg_money)

      assert ana_after == ana_before + 5 + 3
      assert bob_after == bob_before + 2 + 1
      assert charlie_after == charlie_before
      assert david_after == david_before
      assert edward_after == edward_before
    end

    test "Bet money calculated correctly, other winner set", context do
      # ana
      gt1 =
        GameTable.action(context.gametable, {:bet_on_leg, :black})
        # bob
        |> GameTable.action({:bet_on_leg, :blue})
        # charlie
        |> GameTable.action(:shake)
        # david
        |> GameTable.action(:shake)
        # edward
        |> GameTable.action(:shake)
        # ana
        |> GameTable.action({:bet_on_leg, :black})
        # bob
        |> GameTable.action({:bet_on_leg, :black})
        # charlie
        |> GameTable.action(:shake)
        # david
        |> GameTable.action({:bet_on_leg, :green})
        # edward
        |> GameTable.action(:shake)

      gt1 = %GameTable{
        gt1
        | game_board: %{
            gt1.game_board
            | camels: [{3, [:blue, :black]}, {2, [:orange]}, {1, [:green, :red]}]
          }
      }

      %{
        playersmoney: %{
          ana: ana_before,
          bob: bob_before,
          charlie: charlie_before,
          david: david_before,
          edward: edward_before
        }
      } = gt1

      %{
        playersmoney: %{
          ana: ana_after,
          bob: bob_after,
          charlie: charlie_after,
          david: david_after,
          edward: edward_after
        }
      } = GameTable.action(gt1, :get_leg_money)

      assert ana_after == ana_before + 1 + 1
      assert bob_after == bob_before + 5 + 1
      assert charlie_after == charlie_before
      assert david_after == david_before - 1
      assert edward_after == edward_before
    end

    test "After getting legs money, new bets are clean from previous leg bets", context do
      # ana
      gt1 =
        GameTable.action(context.gametable, {:bet_on_leg, :black})
        # bob
        |> GameTable.action({:bet_on_leg, :blue})
        # charlie
        |> GameTable.action(:shake)
        # david
        |> GameTable.action(:shake)
        # edward
        |> GameTable.action(:shake)
        # ana
        |> GameTable.action({:bet_on_leg, :black})
        # bob
        |> GameTable.action({:bet_on_leg, :black})
        # charlie
        |> GameTable.action(:shake)
        # david
        |> GameTable.action({:bet_on_leg, :green})
        # edward
        |> GameTable.action(:shake)

      gt2 =
        gt1
        |> GameTable.action(:get_leg_money)
        # ana
        |> GameTable.action({:bet_on_leg, :black})
        # bob
        |> GameTable.action({:bet_on_leg, :blue})
        # charlie
        |> GameTable.action({:bet_on_leg, :green})
        # david
        |> GameTable.action({:bet_on_leg, :orange})
        # edward
        |> GameTable.action({:bet_on_leg, :red})

      assert %{
               :ana => [{:black, 5}],
               :bob => [{:blue, 5}],
               :charlie => [{:green, 5}],
               :david => [{:orange, 5}],
               :edward => [{:red, 5}]
             } = gt2.playersbet
    end

    test "Desert tiles doesnt mess camels rankings", context do
      # ana
      gt1 =
        GameTable.action(context.gametable, {:bet_on_leg, :black})
        # bob
        |> GameTable.action({:bet_on_leg, :blue})
        # charlie
        |> GameTable.action(:shake)
        # david
        |> GameTable.action(:shake)
        # edward
        |> GameTable.action(:shake)
        # ana
        |> GameTable.action({:bet_on_leg, :black})
        # bob
        |> GameTable.action({:bet_on_leg, :black})
        # charlie
        |> GameTable.action(:shake)
        # david
        |> GameTable.action({:bet_on_leg, :green})
        # edward
        |> GameTable.action(:shake)

      gt1 = %GameTable{
        gt1
        | game_board: %{
            gt1.game_board
            | camels: [
                {15, {:oasis, :ana}},
                {13, {:oasis, :bob}},
                {3, [:blue, :black]},
                {2, [:orange]},
                {1, [:green, :red]}
              ]
          }
      }

      %{
        playersmoney: %{
          ana: ana_before,
          bob: bob_before,
          charlie: charlie_before,
          david: david_before,
          edward: edward_before
        }
      } = gt1

      %{
        playersmoney: %{
          ana: ana_after,
          bob: bob_after,
          charlie: charlie_after,
          david: david_after,
          edward: edward_after
        }
      } = GameTable.action(gt1, :get_leg_money)

      assert ana_after == ana_before + 1 + 1
      assert bob_after == bob_before + 5 + 1
      assert charlie_after == charlie_before
      assert david_after == david_before - 1
      assert edward_after == edward_before
    end

    test "Desert tiles doesnt mess camels rankings, 2nd set", context do
      # ana
      gt1 =
        GameTable.action(context.gametable, {:bet_on_leg, :black})
        # bob
        |> GameTable.action({:bet_on_leg, :blue})
        # charlie
        |> GameTable.action(:shake)
        # david
        |> GameTable.action(:shake)
        # edward
        |> GameTable.action(:shake)
        # ana
        |> GameTable.action({:bet_on_leg, :black})
        # bob
        |> GameTable.action({:bet_on_leg, :black})
        # charlie
        |> GameTable.action(:shake)
        # david
        |> GameTable.action({:bet_on_leg, :green})
        # edward
        |> GameTable.action(:shake)

      gt1 = %GameTable{
        gt1
        | game_board: %{
            gt1.game_board
            | camels: [
                {15, {:oasis, :ana}},
                {3, [:blue, :black]},
                {13, {:oasis, :bob}},
                {2, [:orange]},
                {1, [:green, :red]}
              ]
          }
      }

      %{
        playersmoney: %{
          ana: ana_before,
          bob: bob_before,
          charlie: charlie_before,
          david: david_before,
          edward: edward_before
        }
      } = gt1

      %{
        playersmoney: %{
          ana: ana_after,
          bob: bob_after,
          charlie: charlie_after,
          david: david_after,
          edward: edward_after
        }
      } = GameTable.action(gt1, :get_leg_money)

      assert ana_after == ana_before + 1 + 1
      assert bob_after == bob_before + 5 + 1
      assert charlie_after == charlie_before
      assert david_after == david_before - 1
      assert edward_after == edward_before
    end

    test "Desert tiles doesnt mess camels rankings, 3rd set", context do
      # ana
      gt1 =
        GameTable.action(context.gametable, {:bet_on_leg, :black})
        # bob
        |> GameTable.action({:bet_on_leg, :blue})
        # charlie
        |> GameTable.action(:shake)
        # david
        |> GameTable.action(:shake)
        # edward
        |> GameTable.action(:shake)
        # ana
        |> GameTable.action({:bet_on_leg, :black})
        # bob
        |> GameTable.action({:bet_on_leg, :black})
        # charlie
        |> GameTable.action(:shake)
        # david
        |> GameTable.action({:bet_on_leg, :green})
        # edward
        |> GameTable.action(:shake)

      gt1 = %GameTable{
        gt1
        | game_board: %{
            gt1.game_board
            | camels: [
                {15, {:oasis, :ana}},
                {4, [:blue]},
                {13, {:oasis, :bob}},
                {3, [:black]},
                {2, [:orange]},
                {1, [:green, :red]}
              ]
          }
      }

      %{
        playersmoney: %{
          ana: ana_before,
          bob: bob_before,
          charlie: charlie_before,
          david: david_before,
          edward: edward_before
        }
      } = gt1

      %{
        playersmoney: %{
          ana: ana_after,
          bob: bob_after,
          charlie: charlie_after,
          david: david_after,
          edward: edward_after
        }
      } = GameTable.action(gt1, :get_leg_money)

      assert ana_after == ana_before + 1 + 1
      assert bob_after == bob_before + 5 + 1
      assert charlie_after == charlie_before
      assert david_after == david_before - 1
      assert edward_after == edward_before
    end
  end

  describe "Desert tiles system" do
    setup do
      res =
        %GameTable{}
        |> GameTable.addchar(:ana)
        |> GameTable.addchar(:bob)
        |> GameTable.addchar(:charlie)
        |> GameTable.addchar(:david)
        |> GameTable.addchar(:edward)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:start)

      %{gametable: res}
    end

    test "Tile is registered to character", context do
      res =
        context.gametable
        |> GameTable.action({:put_trap, :oasis, 14})
        |> GameTable.action({:put_trap, :mirage, 12})

      assert res.game_board.camels |> Enum.member?({14, {:oasis, :ana}})
      assert res.game_board.camels |> Enum.member?({12, {:mirage, :bob}})
    end

    test "Bob gets credit when tile is stepped on", context do
      newcamels = [
        {4, {:oasis, :bob}},
        {3, {:oasis, :bob}},
        {2, {:oasis, :bob}},
        {1, [:black, :blue, :green, :orange, :red]}
      ]

      gb_new = context.gametable.game_board |> Map.merge(%{camels: newcamels})

      res =
        %{context.gametable | game_board: gb_new}
        # ana shakes
        |> GameTable.action(:shake)

      # ana gets 1 from shaking, bob gets 1 from tile
      assert %{ana: 1, bob: 1} = res.playersmoney
    end

    test "Charlie gets credit when tile is stepped on, 2nd case", context do
      newcamels = [
        {6, {:oasis, :charlie}},
        {5, {:oasis, :charlie}},
        {4, {:oasis, :charlie}},
        {3, [:black, :blue, :green, :orange, :red]}
      ]

      gb_new = context.gametable.game_board |> Map.merge(%{camels: newcamels})

      res =
        %{context.gametable | game_board: gb_new}
        # ana shakes
        |> GameTable.action(:shake)

      # ana gets 1 from shaking, charlie gets 1 form tile
      assert %{ana: 1, charlie: 1} = res.playersmoney
    end

    test "David and Charlie gets credit when tile is stepped on", context do
      res =
        %{
          context.gametable
          | game_board:
              context.gametable.game_board
              |> Map.merge(%{
                camels: [
                  {6, {:oasis, :charlie}},
                  {5, {:oasis, :charlie}},
                  {4, {:oasis, :charlie}},
                  {3, [:black, :blue, :green, :orange, :red]}
                ]
              })
        }
        # ana shakes
        |> GameTable.action(:shake)

      # ana gets 1 from shaking, charlie gets 1 form tile
      assert %{ana: 1, charlie: 1} = res.playersmoney

      res2 =
        %{
          res
          | game_board:
              res.game_board
              |> Map.merge(%{
                camels: [
                  {13, {:oasis, :david}},
                  {12, {:oasis, :david}},
                  {11, {:oasis, :david}},
                  {10, [:black, :blue, :green, :orange, :red]}
                ]
              })
        }
        # bob shakes
        |> GameTable.action(:shake)

      # ana gets 1 from shaking, charlie gets 1 form tile
      assert %{ana: 1, bob: 1, charlie: 1, david: 1} = res2.playersmoney
    end
  end

  describe "Bets on final winner" do
    setup do
      res =
        %GameTable{}
        |> GameTable.addchar(:ana)
        |> GameTable.addchar(:bob)
        |> GameTable.addchar(:charlie)
        |> GameTable.addchar(:david)
        |> GameTable.addchar(:edward)
        |> GameTable.addchar(:frank)
        |> GameTable.addchar(:garry)
        |> GameTable.addchar(:harry)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:start)

      %{gametable: res}
    end

    test "Bets are correctly associated", context do
      gt =
        context.gametable
        # ana bets
        |> GameTable.action({:bet_on_final_winner, :black})
        # bob bets
        |> GameTable.action({:bet_on_final_winner, :blue})
        # bob bets
        |> GameTable.action({:bet_on_final_winner, :green})
        # charlie bets
        |> GameTable.action({:bet_on_final_winner, :orange})
        # edward bets
        |> GameTable.action({:bet_on_final_winner, :red})
        # frank bets
        |> GameTable.action({:bet_on_final_winner, :black})
        # garry bets
        |> GameTable.action({:bet_on_final_winner, :blue})
        # harry bets
        |> GameTable.action({:bet_on_final_winner, :green})

      assert [
               {:black, :ana},
               {:blue, :bob},
               {:green, :charlie},
               {:orange, :david},
               {:red, :edward},
               {:black, :frank},
               {:blue, :garry},
               {:green, :harry}
             ] = gt.game_board.final_winner_bets
    end

    test "Bets give correct money", context do
      gt =
        context.gametable
        # ana bets
        |> GameTable.action({:bet_on_final_winner, :black})
        # bob bets
        |> GameTable.action({:bet_on_final_winner, :black})
        # bob bets
        |> GameTable.action({:bet_on_final_winner, :black})
        # charlie bets
        |> GameTable.action({:bet_on_final_winner, :black})
        # edward bets
        |> GameTable.action({:bet_on_final_winner, :black})
        # frank bets
        |> GameTable.action({:bet_on_final_winner, :black})
        # garry bets
        |> GameTable.action({:bet_on_final_winner, :blue})
        # harry bets
        |> GameTable.action({:bet_on_final_winner, :green})

      gt = %GameTable{
        gt
        | game_board: %{
            gt.game_board
            | camels: [{17, [:black, :blue, :green, :orange, :red]}],
              state: :q3,
              finished: true
          }
      }

      money_after = (gt |> GameTable.action(:get_final_winner_money)).playersmoney
      money_before = context.gametable.playersmoney
      money_delta = money_before |> Map.merge(money_after, fn _k, v1, v2 -> v2 - v1 end)

      assert %{ana: 8, bob: 5, charlie: 3, david: 2, edward: 1, frank: 1, garry: -1, harry: -1} =
               money_after
    end

    test "Cannot bet twice on same color", context do
      gt =
        context.gametable
        # ana bets
        |> GameTable.action({:bet_on_final_winner, :black})
        # bob bets
        |> GameTable.action({:bet_on_final_winner, :black})
        # bob bets
        |> GameTable.action({:bet_on_final_winner, :black})
        # charlie bets
        |> GameTable.action({:bet_on_final_winner, :black})
        # edward bets
        |> GameTable.action({:bet_on_final_winner, :black})
        # frank bets
        |> GameTable.action({:bet_on_final_winner, :black})
        # garry bets
        |> GameTable.action({:bet_on_final_winner, :blue})
        # harry bets
        |> GameTable.action({:bet_on_final_winner, :green})
        # ana bets invalid
        |> GameTable.action({:bet_on_final_winner, :black})

      refute 1 <
               gt.game_board.final_winner_bets
               |> Enum.reduce(
                 [],
                 fn bet, acc ->
                   case bet do
                     {:black, :ana} ->
                       [:found | acc]

                     _ ->
                       acc
                   end
                 end
               )
               |> Enum.count()
    end

    test "Cannot bet on unavaiable cards", context do
      gt =
        context.gametable
        # ana bets
        |> GameTable.action({:bet_on_final_winner, :gray})
        # bob bets
        |> GameTable.action({:bet_on_final_winner, :whatever})

      refute gt.game_board.final_winner_bets |> Enum.member?({:gray, :ana})
      refute gt.game_board.final_winner_bets |> Enum.member?({:whatever, :bob})
    end
  end

  describe "Bets on final looser" do
    setup do
      res =
        %GameTable{}
        |> GameTable.addchar(:ana)
        |> GameTable.addchar(:bob)
        |> GameTable.addchar(:charlie)
        |> GameTable.addchar(:david)
        |> GameTable.addchar(:edward)
        |> GameTable.addchar(:frank)
        |> GameTable.addchar(:garry)
        |> GameTable.addchar(:harry)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:start)

      %{gametable: res}
    end

    test "Bets are correctly associated", context do
      gt =
        context.gametable
        # ana bets
        |> GameTable.action({:bet_on_final_looser, :black})
        # bob bets
        |> GameTable.action({:bet_on_final_looser, :blue})
        # bob bets
        |> GameTable.action({:bet_on_final_looser, :green})
        # charlie bets
        |> GameTable.action({:bet_on_final_looser, :orange})
        # edward bets
        |> GameTable.action({:bet_on_final_looser, :red})
        # frank bets
        |> GameTable.action({:bet_on_final_looser, :black})
        # garry bets
        |> GameTable.action({:bet_on_final_looser, :blue})
        # harry bets
        |> GameTable.action({:bet_on_final_looser, :green})

      assert [
               {:black, :ana},
               {:blue, :bob},
               {:green, :charlie},
               {:orange, :david},
               {:red, :edward},
               {:black, :frank},
               {:blue, :garry},
               {:green, :harry}
             ] = gt.game_board.final_looser_bets
    end

    test "Bets give correct money", context do
      gt =
        context.gametable
        # ana bets
        |> GameTable.action({:bet_on_final_looser, :black})
        # bob bets
        |> GameTable.action({:bet_on_final_looser, :black})
        # bob bets
        |> GameTable.action({:bet_on_final_looser, :black})
        # charlie bets
        |> GameTable.action({:bet_on_final_looser, :black})
        # edward bets
        |> GameTable.action({:bet_on_final_looser, :black})
        # frank bets
        |> GameTable.action({:bet_on_final_looser, :black})
        # garry bets
        |> GameTable.action({:bet_on_final_looser, :blue})
        # harry bets
        |> GameTable.action({:bet_on_final_looser, :green})

      gt = %GameTable{
        gt
        | game_board: %{
            gt.game_board
            | camels: [{17, [:red, :orange, :green, :blue, :black]}],
              state: :q3,
              finished: true
          }
      }

      money_after = (gt |> GameTable.action(:get_final_looser_money)).playersmoney
      money_before = context.gametable.playersmoney
      money_delta = money_before |> Map.merge(money_after, fn _k, v1, v2 -> v2 - v1 end)

      assert %{ana: 8, bob: 5, charlie: 3, david: 2, edward: 1, frank: 1, garry: -1, harry: -1} =
               money_after
    end

    test "Cannot bet twice on same color", context do
      gt =
        context.gametable
        # ana bets
        |> GameTable.action({:bet_on_final_looser, :black})
        # bob bets
        |> GameTable.action({:bet_on_final_looser, :black})
        # bob bets
        |> GameTable.action({:bet_on_final_looser, :black})
        # charlie bets
        |> GameTable.action({:bet_on_final_looser, :black})
        # edward bets
        |> GameTable.action({:bet_on_final_looser, :black})
        # frank bets
        |> GameTable.action({:bet_on_final_looser, :black})
        # garry bets
        |> GameTable.action({:bet_on_final_looser, :blue})
        # harry bets
        |> GameTable.action({:bet_on_final_looser, :green})
        # ana bets invalid
        |> GameTable.action({:bet_on_final_looser, :black})

      refute 1 <
               gt.game_board.final_looser_bets
               |> Enum.reduce(
                 [],
                 fn bet, acc ->
                   case bet do
                     {:black, :ana} ->
                       [:found | acc]

                     _ ->
                       acc
                   end
                 end
               )
               |> Enum.count()
    end

    test "Cannot bet on unavaiable cards", context do
      gt =
        context.gametable
        # ana bets
        |> GameTable.action({:bet_on_final_looser, :gray})
        # bob bets
        |> GameTable.action({:bet_on_final_looser, :whatever})

      refute gt.game_board.final_looser_bets |> Enum.member?({:gray, :ana})
      refute gt.game_board.final_looser_bets |> Enum.member?({:whatever, :bob})
    end
  end

  describe "Bets on finals" do
    setup do
      res =
        %GameTable{}
        |> GameTable.addchar(:ana)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:warmup)
        |> GameTable.action(:start)

      %{gametable: res}
    end

    test "cannot bet on both", context do
      gt =
        context.gametable
        # ana bets
        |> GameTable.action({:bet_on_final_looser, :black})
        # ana bets
        |> GameTable.action({:bet_on_final_winner, :black})

      assert [{:black, :ana}] == gt.game_board.final_looser_bets

      refute [{:black, :ana}] == gt.game_board.final_winner_bets
    end
  end

  describe "Encoding of game table" do
    test "Encoding of typical game case" do
      refStr =
        "{\"state\":\"q1\",\"circuit\":[{\"position\":\"9\",\"items\":\"green\"},{\"position\":\"7\",\"items\":\"black\"},{\"position\":\"5\",\"items\":\"orange, red\"},{\"position\":\"2\",\"items\":\"blue\"}],\"playerStatuses\":[{\"name\":\"ana\",\"money\":1,\"bets\":[{\"color\":\"black\",\"value\":5}]},{\"name\":\"bob\",\"money\":1,\"bets\":[]},{\"name\":\"charlie\",\"money\":3,\"bets\":[{\"color\":\"green\",\"value\":5}]}],\"previousDices\":[\"green\",\"black\"],\"avaiableLegBets\":[{\"color\":\"black\",\"value\":3},{\"color\":\"blue\",\"value\":5},{\"color\":\"green\",\"value\":3},{\"color\":\"orange\",\"value\":5},{\"color\":\"red\",\"value\":5}],\"personalItems\":{\"tiles\":[\"Oasis\",\"Mirage\"],\"finalLegBets\":[\"black\",\"blue\",\"green\",\"red\"]}}"

      {:ok, refMap} = Jason.decode(refStr)

      {:ok, wannaBe} =
        Jason.encode!(
          GameTableCase.middle_of_game_deterministic()
          |> GameTablePrivateView.to_view(:ana)
        )
        |> Jason.decode()

      assert refMap == wannaBe
    end
  end
end
