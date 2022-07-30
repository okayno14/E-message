%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. июль 2022 0:13
%%%-------------------------------------------------------------------
-module(dialogue_service).
-include("entity.hrl").

%% API
-export([containsUser/2,create_dialogue/1,get_dialogues/1]).

create_dialogue(D)->
  F=
    fun()->
      dialogue_repo:write(D)
    end,
  transaction:begin_transaction(F).

get_dialogues(U)->
  F=
    fun()->
      dialogue_repo:read_by_User(U)
    end,
  transaction:begin_transaction(F).


containsUser(#dialogue{users = Users}=_Dialogue, #user{nick = Nick2}=_User) ->
  lists:any(fun(Nick)->Nick=:=Nick2 end,Users).


