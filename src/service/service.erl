%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. июль 2022 17:31
%%%-------------------------------------------------------------------
-module(service).
-author("aleksandr_work").

%% API
-export([extract_single_value/1, extract_values/1]).

%%Обобщенная функция, обрабатывающая результат транзакции,
%%возвращающей результат mnesia:read.
%%Но с точки зрения бизнес-модели результат обязан быть единственным.
extract_single_value(Transaction)->
  case Transaction of
    {error,_R}->{error,_R};
    []->{error,not_found};
    [Res|_]->Res
  end.

%%аналог предыдущей, но предназначена для
%%чтений с несколькими результатами
extract_values(Transaction)->
  case Transaction of
    {error,_Reason}->{error,_Reason};
    []->{error,not_found};
    Res->Res
  end.