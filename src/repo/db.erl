%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. июль 2022 18:26
%%%-------------------------------------------------------------------
-module(db).
-author("aleksandr_work").

%% API
-export([start_db/0]).

%%вызывается функция create_tables
%%таким образом будет единая точка поднятия базы, которая либо создаст пустую,
%%либо откроет заполненну
start_db()->
  ok.
