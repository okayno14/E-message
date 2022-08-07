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

%%write(Con,Dialogue)->
%%  DID = eredis:q(Con,["INCR", "SeqDial"]),
%%  Commited = Dialogue#dialogue{id=DID},
%%  eredis:q(Con,["HSET","Dialogue",])