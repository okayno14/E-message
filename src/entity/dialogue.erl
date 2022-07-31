%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. июль 2022 11:44
%%%-------------------------------------------------------------------
-module(dialogue).
-include("entity.hrl").

%% API
-export([containsUser/2,add_message/2]).

containsUser(#dialogue{users = Users}=_Dialogue, #user{nick = Nick2}=_User) ->
  lists:any(fun(Nick)->Nick=:=Nick2 end,Users).

add_message(#dialogue{messages = Messages}=D,#message{id = MID})->
  case Messages of
    undefined->D#dialogue{messages = [MID]};
    List->D#dialogue{messages = [MID|List]}
  end.
