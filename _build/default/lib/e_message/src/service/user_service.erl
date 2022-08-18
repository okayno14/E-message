%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. июль 2022 13:01
%%%-------------------------------------------------------------------
-module(user_service).
-include("../../include/entity.hrl").


%% API
-export([create_user/2,
        get_user/3]).

create_user(User, Con)->
  F=
    fun()->
      user_repo:write(User, Con)
    end,
  redis_transaction:begin_transaction(F).

get_user(Nick,Pass, Con)->
  F=
    fun()->
      user_repo:read(Nick,Pass, Con)
    end,
  T= redis_transaction:begin_transaction(F),
  service:extract_single_value(T).


