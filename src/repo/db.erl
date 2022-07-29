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
%%либо откроет заполненную
start_db()->
  create_schema(),
  io:format("Schema created~n"),
  application:start(mnesia),
  io:format("DB started~n"),
  create_tables(),
  io:format("Tables created~n"),
  wait_tables(),
  io:format("Tables initialized~n").

create_schema()->
  mnesia:create_schema([node()]).

%%Вызывает create_table первой сущности.
%%Если вернулась ошибка, то ничего. Иначе - создать все оставшиеся сущности
create_tables()->
  case user_repo:create_table() of
    {atomic,_}->
      io:format("need more tables~n"),
      ok;
    {aborted,_Reason}->
      ok
  end.

wait_tables()->
  mnesia:wait_for_tables([user,dialogue,seq,message],infinity).