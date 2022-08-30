%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. июль 2022 13:10
%%%-------------------------------------------------------------------
-module(user_controller).
-include_lib("e_message/include/entity.hrl").

%% API
-export([create_user/2,
          get_user/3,
          delete_user/2]).

create_user(User, Con)->
  error_catcher:handle(user_service:create_user(User, Con)).

get_user(Nick,Pass, Con)->
  error_catcher:handle(user_service:get_user(Nick,Pass, Con)).

delete_user(User, Con)->
  error_catcher:handle(user_service:delete_user(User, Con)).