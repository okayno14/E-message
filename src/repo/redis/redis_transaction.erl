%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. авг. 2022 10:21
%%%-------------------------------------------------------------------
-module(redis_transaction).
-author("aleksandr_work").
-export([begin_transaction/1,
        abort_transaction/0]).

begin_transaction(Fun)->
  case Fun() of
    {error,_R}->{error,_R};
    Res -> Res
  end.

abort_transaction()->
  throw(transaction_aborted).
