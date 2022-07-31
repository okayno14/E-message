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
-export([create_dialogue/1,
        get_dialogue/1,
        get_dialogues/1,
        get_messages/1,
        quit_dialogue/2,
        add_message/2,
        delete_dialogue/1]).

create_dialogue(Dialogue)->
  dialogue_service:create_dialogue(Dialogue).

get_dialogue(ID)->
  dialogue_service:get_dialogue(ID).

get_dialogues(U)->
  dialogue_service:get_dialogues(U).

quit_dialogue(D,U)->
  dialogue_service:quit_dialogue(D,U).

get_messages(D)->
  dialogue_service:get_messages(D).

add_message(D,M)->
  dialogue_service:add_message(D,M).

delete_dialogue(D)->
  dialogue_service:delete_dialogue(D).
