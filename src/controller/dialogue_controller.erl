%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. июль 2022 10:40
%%%-------------------------------------------------------------------
-module(dialogue_controller).
-include("entity.hrl").

%% API
-export([create_dialogue/1,get_dialogues/1]).

create_dialogue(Dialogue)->
  dialogue_service:create_dialogue(Dialogue).

get_dialogues(U)->
  dialogue_service:get_dialogues(U).
