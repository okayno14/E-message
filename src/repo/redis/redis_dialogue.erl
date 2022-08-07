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
-export([write/2]).

write(Con,Dialogue)->
  {ok, DID} = eredis:q(Con,["INCR", "SeqDial"]),
  Commited = Dialogue#dialogue{id=DID},
  {ok,_} = eredis:q(Con,["HSET",atom_to_list(dialogue),DID,?record_to_json(dialogue,Commited)]),
  Commited.