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
-export([create_user/1,get_user/2]).

create_user(User)->
  user_service:create_user(User).

get_user(Nick,Pass)->
  user_service:get_user(Nick,Pass).