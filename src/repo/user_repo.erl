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
-export([create_table/0,
        write/2,
        read/2,
        read/3,
        update/2,
        delete/2]).

create_table()-> ok.

write(User, Con)->
  redis_user:write(Con,User).

read(Nick, Con)->
  redis_user:read(Con,Nick).

read(Nick,Pass, Con)->
  U=read(Nick, Con),
  case U of
    [User|_] when User#user.pass =:= Pass->
      [User];
    [User|_] when User#user.pass =/= Pass->
      [];
    [] -> []
  end.

update(UserNew, Con) ->
  redis_user:update(Con,UserNew).

delete(#user{nick = Nick}, Con) ->
  redis_user:delete(Con,Nick).