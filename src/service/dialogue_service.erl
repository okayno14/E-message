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
-export([containsUser/2]).

containsUser(#dialogue{users = Users}=_Dialogue, #user{nick = Nick2}=_User)->
  lists:any(fun(Nick)->Nick=:=Nick2 end,Users).