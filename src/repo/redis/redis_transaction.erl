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

%% API
-export([exec_transaction/2]).

%%{ok, Res} || {error, Cause}
exec_transaction(_DB_SRV,_Fun)->
  {error, not_supported}.
