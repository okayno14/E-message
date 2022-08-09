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
-export([extract_single_value/1,
        extract_multiple_values/1]).

%%Функция обработки read-операции репозитория.
%%Необходима, если с точки зрения бизнес-процесса результат:
%%    1) обязан быть найден
%%    2) должен быть единственным
extract_single_value(Transaction)->
  case Transaction of
    {error,_R}->{error,_R};
    []->{error,not_found};
    [Res|_]->Res
  end.

%%Функция обработки read-операции репозитория.
%%Необходима, если с точки зрения бизнес-процесса результат:
%%    1) обязан быть найден
%%    2) допускается несколько объектов
extract_multiple_values(Transaction)->
  case Transaction of
    {error,_Reason}->{error,_Reason};
    []->{error,not_found};
    Res->Res
  end.