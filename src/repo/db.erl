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

%% API
-export([start_db/0,
        start_db/4]).

start_db()->
  redis_db:start_db().

start_db(Domain,Port,_User,Pass)->
  redis_db:start_db(Domain,Port,_User,Pass).