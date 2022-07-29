%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. июль 2022 11:19
%%%-------------------------------------------------------------------
-module(transaction).
-author("aleksandr_work").

%% API
-export([begin_transaction/1]).

begin_transaction(Fun)->
  case mnesia:transaction(Fun) of
    {atomic, _Res}->_Res;
    {aborted, _Reason}-> {error,_Reason}
  end.