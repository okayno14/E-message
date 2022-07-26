%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. авг. 2022 12:11
%%%-------------------------------------------------------------------
-module(db).
-author("aleksandr_work").
-export([start_db/0,
        start_db/5,
        clean_db/1]).

%%Модуль для управления соединением с бд

%%Подключиться к БД, создать структуры, если их нет
%%{ok, Connection}
%%{error, Cause}
start_db()->
  redis_db:start_db().

%%Подключиться к БД, создать структуры, если их нет
%%{ok, Connection}
%%{error, Cause}
start_db(Domain,Port,Database,_User,Pass)->
  redis_db:start_db(Domain,Port,Database,_User,Pass).

clean_db(Con)->
  redis_db:clean_db(Con).