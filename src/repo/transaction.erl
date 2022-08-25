%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. июль 2022 11:19
%%%-------------------------------------------------------------------
-module(transaction).
-export([begin_transaction/1,
        abort_transaction/0]).

%%Res || {error, Cause}

%%Fun/0 функция с телом транзакции.
%%Тело транзакции - набор действий языка среди которых есть операции, предоставляемые репозиторием.
%%Каждая функция репозитория - обращение к базе
%%Следовательно, заворачивая множество функций репозитория в транзакции мы заворачиваем и обращения к базе.
%%Транзакция исполняется если её не отменили.
begin_transaction(Fun)->
  try
    redis_transaction:begin_transaction(Fun)
  catch
    throw:transaction_aborted -> {error, transaction_aborted}
  end.

%%функция внутри должна послать сообщение базе об отмене транзакции и
%%выбросить исключение transaction_aborted
abort_transaction()->
  redis_transaction:abort_transaction().