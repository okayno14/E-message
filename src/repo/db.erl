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

start_db()->
  application:start(mnesia),
  create_schema().
  %%вызывается функция create_tables
  %%таким образом будет единая точка поднятия базы, которая либо создаст пустую,
  %%либо откроет заполненную

create_schema()->
  mnesia:create_schema([node()]).

%%Вызывает create_table первой сущности.
%%Если вернулась ошибка, то ничего. Иначе - создать все оставшиеся сущности
%%create_tables()->.
