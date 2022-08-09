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
-export([begin_transaction/1,
        abort_transaction/0]).

%%Fun/0 функция с телом транзакции.
%%Тело транзакции - набор действий языка среди которых есть операции, предоставляемые репозиторием.
%%Каждая функция репозитория - обращение к базе
%%Следовательно, заворачивая множество функций репозитория в транзакции мы заворачиваем и обращения к базе.
%%Транзакция исполняется если её не отменили.
begin_transaction(Fun)->
  redis_transaction:begin_transaction(Fun).

abort_transaction()->
  redis_transaction:abort_transaction().