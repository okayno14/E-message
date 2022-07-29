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
-export([create_user/1]).

create_user(User)->
  F=
    fun()->
      user_repo:write(User)
    end,
  transaction:begin_transaction(F).

