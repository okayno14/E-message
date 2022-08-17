%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. июль 2022 13:10
%%%-------------------------------------------------------------------
-module(user_controller).
-include("../../include/entity.hrl").

%% API
-export([create_user/2,
          get_user/3]).

create_user(User, Con)->
  user_service:create_user(User, Con).

get_user(Nick,Pass, Con)->
  user_service:get_user(Nick,Pass, Con).