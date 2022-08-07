%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. авг. 2022 10:21
%%%-------------------------------------------------------------------
-module(redis_user).
-include("entity.hrl").
-include("jsonerl/jsonerl.hrl").

%% API

%% операции чтения - фильтры, поэтому они возвращают
%% пустой или заполненный список

%% на вход всегда принимаются:
%%     дескриптор соединения, сущность
%%     дескриптор соединения, ключи поиска
-export([write/2,
        read/2,
        read/3,
        update/2,
        delete/2]).

write(Con,#user{nick = Nick}=User)->
  case read(Con,Nick) of
    [] ->
      eredis:q(Con,["HSET", atom_to_list(user), Nick, ?record_to_json(user,User)]),
      User;
    _Obj -> {error, already_exists}
  end.

read(Con,Nick)->
  case eredis:q(Con,["HGET",atom_to_list(user),Nick]) of
    {ok, undefined}-> [];
    {ok, JSON}->
      [?json_to_record(user,JSON)]
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
  eredis:q(Con,["HSET", atom_to_list(user), Nick, ?record_to_json(user,User)]),
  User.

delete(Con,#user{nick = Nick})->
  eredis:q(Con,["HDEL",atom_to_list(user), Nick]).