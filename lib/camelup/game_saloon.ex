defmodule CamelUp.GameSaloon do
  alias CamelUp.{GameSaloon, GameTable}

  defstruct tables: %{},
            uuid_to_table_id: %{}

  # @type tables :: %{any() => %GameTable{}}
  #

  def be_joined_by_user(%GameSaloon{} = gr, %{:char => _, :uuid => _} = user, room)
      when is_integer(room) do
    gt_base =
      case gr.tables |> Map.get(room) do
        nil ->
          %GameTable{}

        %GameTable{} = answer ->
          answer
      end

    gt_new = gt_base |> GameTable.addchar(user.char)

    %GameSaloon{
      gr
      | tables: gr.tables |> Map.put(room, gt_new),
        uuid_to_table_id: gr.uuid_to_table_id |> Map.put(user.uuid, room)
    }
  end

  def get_table_by_id(%GameSaloon{} = gr, id) when is_integer(id) do
    case gr.tables |> Map.get(id) do
      nil ->
        {:error}

      %GameTable{} = gt ->
        {:ok, gt}
    end
  end

  def be_left_by_user(%GameSaloon{} = gs, %{:uuid => _} = user) do
    user_table_id = gs |> get_user_table_id(user.uuid)
    {:ok, gt} = gs |> get_table_by_id(user_table_id)
    gt = gt |> GameTable.removechar(user.char)
    gs = %GameSaloon{gs | tables: gs.tables |> Map.replace!(user_table_id, gt)}
    gs
  end

  def get_user_table_id(%GameSaloon{} = gs, uuid) do
    gs.uuid_to_table_id |> Map.fetch!(uuid)
  end

  def user_action(%GameSaloon{} = gs, %{:uuid => _} = user, action) do
    table_id = gs |> get_user_table_id(user.uuid)
    {:ok, table} = gs |> get_table_by_id(table_id)
    new_table = table |> GameTable.action(action)
    %GameSaloon{gs | tables: gs.tables |> Map.put(table_id, new_table)}
  end
end
