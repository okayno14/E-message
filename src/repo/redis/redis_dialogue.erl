%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. авг. 2022 10:21
%%%-------------------------------------------------------------------
-module(redis_dialogue).
-include("entity.hrl").
-include("jsonerl/jsonerl.hrl").

%% API
-export([write/2,
        read/2]).

write(Con,#dialogue{users = Nicks} = Dialogue)->
  {ok, DID} = eredis:q(Con,["INCR", "SeqDial"]),
  Commited = Dialogue#dialogue{id=DID},
  {ok,_} = eredis:q(Con,["HSET",atom_to_list(dialogue),DID,?record_to_json(dialogue,Commited)]),

  eredis:q(Con,["MULTI"]),
  lists:map(
    fun(Nick)->
      Str = string:concat(binary_to_list(Nick),":dialogue"),
      io:format("~p~n",[Str]),
      eredis:q(Con,["SADD", Str, DID])
    end,
    Nicks),
  {ok,_} = eredis:q(Con,["EXEC"]),
  Commited.

read(Con, DID)->
  {ok, T} = eredis:q(Con,["HGET",atom_to_list(dialogue),DID]),
  case T of
    undefined->[];
    _ ->
      [?json_to_record(dialogue,T)]
  end.

