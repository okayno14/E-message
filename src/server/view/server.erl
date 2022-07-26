%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. июль 2022 11:23
%%%-------------------------------------------------------------------
-module(server).
-author("aleksandr_work").

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
      io:format("Socket ~w [~w] receive request ~n", [Socket, self()]),
      gen_tcp:send(Socket, Request),
      loop(Socket);
    {tcp_closed,Socket}->
      io:format("Socket ~w closed [~w]~n",[Socket,self()]),
      ok
  end.

%%обработка клиентских запросов
%%process_request

