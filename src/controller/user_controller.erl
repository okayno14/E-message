%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. июль 2022 13:10
%%%-------------------------------------------------------------------
-module(user_controller).
-include("entity.hrl").

%% API
-export([create_user/1]).

create_user(User)->
  Res=user_service:create_user(User),
  io:format("Controller ok. ~p~n",[Res]),
  Res.