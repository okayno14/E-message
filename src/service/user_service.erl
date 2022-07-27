%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. июль 2022 15:28
%%%-------------------------------------------------------------------

-module(user_service).
-include("user.hrl").

%% API
-export([foo/0, create_tables/0,read/0,update/0]).



foo()->
  start_db(),
  Person1=#user{nick="vasya228"},
  A=Person1#user{firstname = "Vasiliy"},
  B=A#user{lastname = "Ivanov"},
  B,
  wait_for_init(),
  {atomic,ok}=mnesia:transaction(fun()-> mnesia:write(B) end).

read()->
  start_db(),
  wait_for_init(),
  {atomic, [Obj|_Tail]}=mnesia:transaction(fun()->mnesia:read(user,"vasya228") end),
  io:format("Readed object =  ~p~n",[Obj]),
  Obj.

update()->
  start_db(),
  wait_for_init(),
  Obj = read(),
  Obj1 = Obj#user{fathername = "Vasilyevich"},
  io:format("Updated object = ~p~n",[Obj1]),
  {atomic,ok}=mnesia:transaction(fun()-> mnesia:write(Obj1) end),
  io:format("Object vasya228 updated ~p~n",[Obj1]).

wait_for_init()->
  case mnesia:wait_for_tables([user], infinity) of
    {timeout,_TableList}->io:format("Timeout~n");
    ok->io:format("table loaded~n");
    {error,Reason}->io:format("table failed loading ~p~n",[Reason])
  end.

create_tables()->
  create_schema(),
  Fields = record_info(fields,user),
  io:format("~p~n", [Fields]),
  start_db(),
  Table = mnesia:create_table(user,[
    {record_name,user},
    {type, set},
    {attributes,record_info(fields,user)},
    {disc_copies, [node()]}]),
  io:format("~p~n",[Table]).

start_db()->
  application:start(mnesia).

create_schema()->
  Schema = mnesia:create_schema([node()]),
  io:format("~p~n",[Schema]).

