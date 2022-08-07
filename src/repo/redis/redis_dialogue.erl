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
-export([]).

write(Con,Dialogue)->
  DID = eredis:q(Con,["INCR", "SeqDial"]),
  Commited = Dialogue#dialogue{id=DID},
  W = eredis:q(Con,["HSET",atom_to_list(dialogue),DID,?record_to_json(dialogue,Commited)]),
  case W of
    {error,_R}->{error,_R};
    {ok,_}->Commited
  end.