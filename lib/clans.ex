defmodule Clans do
  use Application

  def start(_type, _args) do
    children = [{Clans.Server, [Application.get_env(:clans, :db)]}]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def create(who, clan_name, clan_tag)
      when is_binary(clan_name) and
           is_binary(clan_tag) and
           :erlang.size(clan_tag) == 3 do
    Clans.Server.create(who, clan_name, clan_tag)
  end

  def invite(who, whom, clan_name) do
    if who == whom do
      {:error, :cannot_invite_yourself}
    else
      Clans.Server.invite(who, whom, clan_name)
    end
  end

  def kick(who, whom, clan_name) do
    Clans.Server.kick(who, whom, clan_name)
  end

  def transfer(who, whom, clan_name) do
    if who == whom do
      {:error, :are_you_kidding_me?}
    else
      Clans.Server.transfer(who, whom, clan_name)
    end
  end

  def accept_invite(who, clan_name) do
    Clans.Server.accept_invite(who, clan_name)
  end

  def refuse_invite(who, clan_name) do
    Clans.Server.refuse_invite(who, clan_name)
  end

  def whereis(who) do
    Clans.Server.whereis(who)
  end
end
