%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. авг. 2022 10:21
%%%-------------------------------------------------------------------
-module(redis_message).
-include("entity.hrl").
-include("jsonerl/jsonerl.hrl").

%% API
-export([write/2]).

write(Con,#message{}= Message)->
  {ok,MID}=eredis:q(Con,["INCR","SeqMsg"]),
  Commited = Message#message{id = MID},
  {ok,_}=eredis:q(Con,["HSET",atom_to_list(message),MID,?record_to_json(message,Commited)]),
  Commited.

