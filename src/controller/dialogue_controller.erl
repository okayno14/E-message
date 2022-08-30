%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. июль 2022 10:40
%%%-------------------------------------------------------------------
-module(dialogue_controller).

-include_lib("e_message/include/entity.hrl").

%% API
-export([create_dialogue/2,
        get_dialogue/2,
        get_dialogues/2,
        get_message/4,
        get_messages/3,
        quit_dialogue/3,
        add_message/3,
        read_message/4,
        change_text/4,
        delete_message/4,
        delete_dialogue/2]).

create_dialogue(Dialogue, Con)->
  error_catcher:handle(dialogue_service:create_dialogue(Dialogue, Con)).

get_dialogue(ID, Con)->
  error_catcher:handle(dialogue_service:get_dialogue(ID, Con)).

get_dialogues(U, Con)->
  error_catcher:handle(dialogue_service:get_dialogues(U, Con)).

quit_dialogue(D,U, Con)->
  error_catcher:handle(dialogue_service:quit_dialogue(D,U, Con)).

get_message(U,MID,DID,Con)->
  error_catcher:handle(dialogue_service:get_message(U,MID,DID,Con)).

get_messages(User,D, Con)->
  error_catcher:handle(dialogue_service:get_messages(User,D, Con)).

add_message(D,M, Con)->
  dialogue_service:add_message(D,M, Con).

read_message(U,M,D,Con)->
  dialogue_service:read_message(U,M,D,Con).

change_text(User,M,Text,Con)->
  dialogue_service:change_text(User,M,Text,Con).

delete_message(D,M,U, Con)->
  dialogue_service:delete_message(D,M,U, Con).

delete_dialogue(D, Con)->
  dialogue_service:delete_dialogue(D, Con).
