%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. июль 2022 18:21
%%%-------------------------------------------------------------------
-module(user_repo).
-include_lib("e_message/include/entity.hrl").
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

%%Если произошла ошибка соединения с источником -> значит, что вся система становится бесполезной->
%%ошибка критическая и должна быть послана на самый верх

%%нельзя создавать новый объект с зарегистрированным идентификатором
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

delete(U, Con) ->
  redis_user:delete(Con,U).