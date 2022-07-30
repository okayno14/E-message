%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. июль 2022 18:21
%%%-------------------------------------------------------------------
-module(user_repo).
-include("entity.hrl").

%% API
-export([create_table/0,write/1,read/1,read/2,update/1,delete/1]).

create_table()->
  mnesia:create_table(user,
    [
      {record_name, user},
      {type, set},
      {attributes, record_info(fields,user)},
      {disc_copies, [node()]}
    ]).

write(User)->
  case read(User#user.nick) of
    []->
      mnesia:write(User),
      User;
    _Obj->transaction:abort_transaction(already_exists)
  end.

read(Nick)->
  mnesia:read(user,Nick).

read(Nick,Pass)->
  U=read(Nick),
  case U of
    [User|_] when User#user.pass =:= Pass->
      User;
    [User|_] when User#user.pass =/= Pass->
      [];
    [] -> []
  end.

update(UserNew) ->
  mnesia:write(UserNew).

delete(User) ->
  Nick = User#user.nick,
  mnesia:delete({user,Nick}).