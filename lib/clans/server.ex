defmodule Clans.Server do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: Clans.Server)
  end

  def create(who, name, tag) do
    call({:create, who, name, tag})
  end

  def invite(who, whom, name) do
    call({:invite, who, whom, name})
  end

  def kick(who, whom, name) do
    call({:kick, who, whom, name})
  end

  def transfer(who, whom, name) do
    call({:transfer, who, whom, name})
  end

  def accept_invite(who, name) do
    call({:accept_invite, who, name})
  end

  def refuse_invite(who, name) do
    call({:refuse_invite, who, name})
  end

  def whereis(who) do
    call({:whereis, who})
  end

  ## Server Callbacks

  def init([db_path]) do
    :dets.open_file(Clans, access: :read_write, type: :set, file: db_path)
  end

  def handle_call({:create, who, name, tag}, _from, state) do
    match = [
      {{{:meta, name}, :_}, [], [:name_taken]},
      {{{:meta, :_}, %{tag: tag}}, [], [:tag_taken]}]
    resp =
      case db(:select, match, 1) do
        :"$end_of_table" ->
          :ok = db(:insert, {{:meta, name}, %{leader: who, tag: tag}})
          :ok = db(:insert, {{:player, name, who}})
        {[reason], _} ->
          {:error, reason}
      end
    {:reply, resp, state}
  end

  def handle_call({:invite, who, whom, name}, _from, state) do
    resp =
      cond do
        not db(:member, {:player, name, who}) ->
          {:error, :not_authorized}
        db(:member, {:player, name, whom}) ->
          {:error, :already_member}
        true ->
          if db(:insert_new, {{:invite, name, whom}}) do
            :ok
          else
            {:error, :already_invited}
          end
      end
    {:reply, resp, state}
  end

  def handle_call({:accept_invite, who, name}, _from, state) do
    resp =
      cond do
        not db(:member, {:invite, name, who}) ->
          {:error, :invite_not_found}
        true ->
          :ok = db(:delete, {:invite, name, who})
          :ok = db(:insert, {{:player, name, who}})
      end
    {:reply, resp, state}
  end

  def handle_call({:refuse_invite, who, name}, _from, state) do
    resp =
      cond do
        not db(:member, {:invite, name, who}) ->
          {:error, :invite_not_found}
        true ->
          db(:delete, {:invite, name, who})
      end
    {:reply, resp, state}
  end

  def handle_call({:transfer, who, whom, name}, _from, state) do
    resp =
      case get_meta(name) do
        {:ok, %{:leader => leader} = meta} ->
          cond do
            who != leader ->
              {:error, :not_authorized}
            not db(:member, {:player, name, whom}) ->
              {:error, :can_transfer_only_to_member}
            true ->
              :ok = db(:insert, {{:meta, name}, Map.put(meta, :leader, whom)})
          end
        {:error, :clan_not_found} = error ->
          error
      end
    {:reply, resp, state}
  end

  def handle_call({:kick, who, whom, name}, _from, state) do
    resp =
      case get_meta(name) do
        {:ok, %{:leader => leader}} ->
          cond do
            not db(:member, {:player, name, whom}) ->
              {:error, :can_kick_only_member}
            who != leader and who != whom ->
              {:error, :not_authorized}
            whom == leader ->
              {:error, :cannot_kick_leader}
            true ->
              :ok = db(:delete, {:player, name, whom})
          end
        {:error, :clan_not_found} = error ->
          error
      end
    {:reply, resp, state}
  end

  def handle_call({:whereis, who}, _from, state) do
    resp =
      Enum.map(
        db(:match, {{:player, :"$1", who}}),
        fn [name] ->
          {:ok, %{:leader => leader}} = get_meta(name)
          %{name: name, leader?: who == leader}
        end)
    {:reply, resp, state}
  end

  # other stuff

  defp get_meta(name) do
    case db(:lookup, {:meta, name}) do
      [] -> {:error, :clan_not_found}
      [{_, meta}] -> {:ok, meta}
    end
  end

  defp db(fun, arg1) do
    apply(:dets, fun, [Clans, arg1])
  end

  defp db(fun, arg1, arg2) do
    apply(:dets, fun, [Clans, arg1, arg2])
  end

  defp call(args) do
    GenServer.call(__MODULE__, args)
  end
end
