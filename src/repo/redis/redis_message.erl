%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. авг. 2022 10:21
%%%-------------------------------------------------------------------
-module(redis_message).
-include("../../include/entity.hrl").
-include("../../_build/default/lib/jsonerl/include/jsonerl.hrl").
-export([write/2,
        read/2,
        update/2,
        delete/2]).

%% на вход всегда принимаются:
%%     дескриптор соединения, сущность
%%     дескриптор соединения, ключи поиска

%%create-операции должны возвращать 1 персистентный объект
%%read-операции - фильтры, поэтому они возвращают пустой или заполненный список
%%update-операции - возвращают новый объект
%%delete - ok

write(Con,#message{}=Message)->
  {ok,MID}=eredis:q(Con,["INCR","SeqMsg"]),
  Commited = Message#message{id = binary_to_integer(MID)},
  {ok,_}=eredis:q(Con,["HSET",atom_to_list(message),MID,?record_to_json(message,Commited)]),
  Commited.

read(Con,MID) when MID =/= -1 ->
  {ok,JSON} = eredis:q(Con,["HGET",atom_to_list(message),MID]),
  [?json_to_record(message,JSON)].

update(Con,#message{id = MID}=Message)->
  {ok,_}=eredis:q(Con,["HSET",atom_to_list(message),MID,?record_to_json(message,Message)]),
  Message.

delete(Con,#message{id=MID})->
  {ok,_} = eredis:q(Con,["HDEL",atom_to_list(message),MID]),
  ok.