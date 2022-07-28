%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. июль 2022 11:23
%%%-------------------------------------------------------------------
-module(server).
-include("jsonerl/jsonerl.hrl").
-include("request.hrl").
%% API
-export([start/0, wait_request/1]).

start() ->
  case  gen_tcp:listen(5560,[{active, false}]) of
    {ok, ListenSocket}->
      io:format("~w Acceptors will spawn~n",[8]),
      start_servers(8,ListenSocket),
      %%замораживает listen-процесс
      timer:sleep(infinity);
    {error, Reason}->io:format("Error, can't listen port ~w~n", [Reason])
  end.

start_servers(0,_)-> ok;
start_servers(Num, ListenSocket)->
  spawn(?MODULE,wait_request,[ListenSocket]),
  io:format("Acceptor#~w spawned~n",[Num]),
  start_servers(Num-1,ListenSocket).

wait_request(ListenSocket)->
  case gen_tcp:accept(ListenSocket) of
    {ok, Socket} ->
      loop(Socket),
      wait_request(ListenSocket);
    {error, Reason}->io:format("Error, can't accept request. ~w~n",[Reason])
  end.

%%функция-цикл работы потока-акцептора
loop(Socket)->
  inet:setopts(Socket,[{active,once}]),
  receive
    {tcp,Socket,Request}->
      io:format("Socket ~w [~w] received request ~n", [Socket, self()]),
      io:format("Requset data: ~p~n", [Request]),
      process_request(Socket,Request),
      loop(Socket);
    {tcp_closed,Socket}->
      io:format("Socket ~w closed [~w]~n",[Socket,self()]),
      ok
  end.

%%обработка клиентских запросов
process_request(_Socket, Request)->
  [Fun, ArgsJSON]=string:split(Request,"\n\n"),
  io:format("~p~n~p~n",[Fun, ArgsJSON]),
  Args=?json_to_record(hello, ArgsJSON),
  Res = Args#hello.x+Args#hello.y,
  io:format("~w~n",[Res]).

