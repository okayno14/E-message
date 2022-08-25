%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. авг. 2022 10:21
%%%-------------------------------------------------------------------
-module(redis_user).
-include_lib("e_message/include/entity.hrl").
-include_lib("jsonerl/include/jsonerl.hrl").
-export([write/2,
        read/2,
        read/3,
        update/2,
        delete/2]).

%% на вход всегда принимаются:
%%     дескриптор соединения, сущность
%%     дескриптор соединения, ключи поиска

%%create-операции должны возвращать 1 персистентный объект
%%read-операции - фильтры, поэтому они возвращают пустой или заполненный список
%%update-операции - возвращают новый объект
%%delete - ok
%%ошибка - {error, Reason}

%%нельзя создавать новый объект с зарегистрированным идентификатором
write(Con,#user{nick = Nick}=User)->
  case read(Con,Nick) of
    [] ->
      {ok,_}=eredis:q(Con,["HSET", atom_to_list(user), Nick, ?record_to_json(user,User)]),
      User;
    _Obj ->
      {error, already_exists}
  end.

read(Con,Nick)->
  {ok, T} = eredis:q(Con,["HGET",atom_to_list(user),Nick]),
  case T of
    undefined ->
      [];
    _->
      [?json_to_record(user,T)]
  end.

read(Con,Nick,Pass)->
  case read(Con,Nick) of
    [User|_] when User#user.pass =:= Pass->
      [User];
    [User|_] when User#user.pass =/= Pass->
      [];
    [] -> []
  end.

update(Con,#user{nick = Nick}=User)->
  {ok,_} = eredis:q(Con,["HSET", atom_to_list(user), Nick, ?record_to_json(user,User)]),
  User.

delete(Con,#user{nick = Nick})->
  {ok,_} = eredis:q(Con,["HDEL",atom_to_list(user), Nick]).