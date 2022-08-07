%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. июль 2022 13:01
%%%-------------------------------------------------------------------
-module(user_service).
-include("entity.hrl").


%% API
-export([create_user/1,get_user/2]).

create_user(User)->
  F=
    fun()->
      user_repo:write(User)
    end,
  transaction:begin_transaction(F).

get_user(Nick,Pass)->
  F=
    fun()->
      user_repo:read(Nick,Pass)
    end,
  T= transaction:begin_transaction(F),
  service:extract_single_value(T).


