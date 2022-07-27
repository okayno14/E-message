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
-export([create/0, create_tables/0,read/0,update/0,delete/0]).

create()->
  start_db(),
  wait_for_init(),
  Person1=#user{nick="vasya228"},
  A=Person1#user{firstname = "Vasiliy"},

  Id = mnesia:dirty_update_counter(seq,user,1),
  B=A#user{lastname = "Ivanov", id = Id},
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

delete()->
  start_db(),
  wait_for_init(),
  {atomic, ok} = mnesia:transaction(fun()-> mnesia:delete({user,"vasya228"}) end),
  {atomic, []} = mnesia:transaction(fun()-> mnesia:read(user, "vasya228") end),
  io:format("Object vasya228 deleted~n").

wait_for_init()->
  case mnesia:wait_for_tables([user,seq], infinity) of
    {timeout,_TableList}->io:format("Timeout~n");
    ok->io:format("table loaded~n");
    {error,Reason}->io:format("table failed loading ~p~n",[Reason])
  end.

create_tables()->
  create_schema(),
  start_db(),

  {atomic, ok} = mnesia:create_table(user,[
    {record_name,user},
    {type, set},
    {attributes,record_info(fields,user)},
    {disc_copies, [node()]}]),

  {atomic,ok} = mnesia:create_table(seq,[
    {record_name,seq},
    {type,set},
    {attributes,record_info(fields,seq)},
    {disc_copies,[node()]}]),

  {atomic,ok} = mnesia:transaction(fun()-> mnesia:write(#seq{table_name=user,counter=0}) end),

  io:format("Tables creation successful!~n").

start_db()->
  application:start(mnesia).

create_schema()->
  Schema = mnesia:create_schema([node()]),
  io:format("~p~n",[Schema]).

