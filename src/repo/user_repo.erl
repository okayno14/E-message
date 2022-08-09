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
-export([write/2,
        read/2,
        read/3,
        update/2,
        delete/2]).

%%create-операции должны возвращать 1 персистентный объект
%%read-операции - фильтры, поэтому они возвращают пустой или заполненный список
%%update-операции - возвращают новый объект
%%delete - ok
%%ошибка - {error, Reason}

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