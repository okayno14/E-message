%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. авг. 2022 10:21
%%%-------------------------------------------------------------------
-module(redis_db).
-author("aleksandr_work").

%% API
-export([start_db/0, start_db/4]).

%%Подключиться к БД, создать структуры, если их нет
%%{ok, Connection}
%%{error, Cause}
start_db()->
  eredis:start_link().

start_db(Domain,Port,User,Pass)->
  connect(Domain,Port,User,Pass).

connect(Domain,Port,_User,Pass)->
  eredis:start_link(Domain, Port, 0, Pass, 0).