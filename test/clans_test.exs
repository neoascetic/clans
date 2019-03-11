defmodule ClansTest do
  use ExUnit.Case
  doctest Clans

  setup do
    :ok = :dets.delete_all_objects(Clans)
  end

  test "creation of a clan" do
    assert Clans.whereis("me") == []
    assert Clans.create("me", "clan", "TAG") == :ok
    assert Clans.whereis("me") == [%{name: "clan", leader?: true}]
    assert Clans.create("me", "clan", "LOL") == {:error, :name_taken}
    assert Clans.create("me", "clan2", "TAG") == {:error, :tag_taken}
    assert Clans.create("me", "clan2", "LOL") == :ok
    assert Clans.whereis("me") == [%{name: "clan", leader?: true},
                                   %{name: "clan2", leader?: true}]
  end

  test "invite to a clan" do
    assert Clans.create("me", "clan", "TAG") == :ok
    assert Clans.invite("me", "you", "clan") == :ok
    assert Clans.whereis("you") == []
    assert Clans.refuse_invite("you", "clan") == :ok
    assert Clans.refuse_invite("you", "clan") == {:error, :invite_not_found}
    assert Clans.accept_invite("you", "clan") == {:error, :invite_not_found}
    assert Clans.invite("me", "you", "clan") == :ok
    assert Clans.accept_invite("you", "clan") == :ok
    assert Clans.whereis("you") == [%{name: "clan", leader?: false}]
  end

  test "kick from a clan" do
    assert Clans.create("me", "clan", "TAG") == :ok
    assert Clans.kick("me", "me", "clan") == {:error, :cannot_kick_leader}
    assert Clans.kick("me", "you", "clan") == {:error, :can_kick_only_member}
    add_to_clan("me", "you", "clan")
    assert Clans.kick("me", "you", "clan") == :ok
    assert Clans.whereis("you") == []
    add_to_clan("me", "you", "clan")
    assert Clans.kick("you", "me", "clan") == {:error, :not_authorized}
    assert Clans.kick("you", "you", "clan") == :ok # leave the clan
    assert Clans.whereis("you") == []
  end

  test "transfer leadership" do
    assert Clans.create("me", "clan", "TAG") == :ok
    assert Clans.transfer("me", "me", "clan") == {:error, :are_you_kidding_me?}
    assert Clans.transfer("me", "you", "clan") == {:error, :can_transfer_only_to_member}
    add_to_clan("me", "you", "clan")
    add_to_clan("me", "he", "clan")
    assert Clans.transfer("you", "he", "clan") == {:error, :not_authorized}
    assert Clans.transfer("me", "you", "clan") == :ok
    assert Clans.whereis("me") == [%{name: "clan", leader?: false}]
    assert Clans.whereis("you") == [%{name: "clan", leader?: true}]
  end

  def add_to_clan(who, whom, clan_name) do
    assert Clans.invite(who, whom, clan_name) == :ok
    assert Clans.accept_invite(whom, clan_name) == :ok
  end

end
