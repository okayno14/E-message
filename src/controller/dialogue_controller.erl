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
-export([create_dialogue/1,get_dialogue/1,get_dialogues/1,delete_dialogue/1,quit_dialogue/2]).

create_dialogue(Dialogue)->
  dialogue_service:create_dialogue(Dialogue).

get_dialogue(ID)->
  dialogue_service:get_dialogue(ID).

get_dialogues(U)->
  dialogue_service:get_dialogues(U).

quit_dialogue(D,U)->
  dialogue_service:quit_dialogue(D,U).

delete_dialogue(D)->
  dialogue_service:delete_dialogue(D).
