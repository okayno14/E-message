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
  T=transaction:begin_transaction(F),
  io:format("get_user(Nick,Pass). Repo returned ~p~n",[T]),
  case T of
    {error,_Reason}->{error,_Reason};
    []->{error,not_found};
    User->User
  end.


