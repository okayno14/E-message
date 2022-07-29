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
-include("entity.hrl").
%% API
-export([start/0, wait_request/1]).

start() ->
  db:start_db(),
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
process_request(Socket, Request)->
  [Fun,ArgsJSON]=parseRequest(Request),
  case Fun of
    create_user->
      Args = ?json_to_record(create_user,ArgsJSON),
      #create_user{nick = Nick,pass = Pass} = Args,
      User = #user{nick = Nick,pass = Pass},
      io:format("Parsed User:~n~p~n",[User]),
      case user_controller:create_user(User) of
        {error,_Reason}->
          ErrorMsg = #error{type = error, msg = _Reason},
          gen_tcp:send(Socket,?record_to_json(error,ErrorMsg));
        _User_P->
          gen_tcp:send(Socket,?record_to_json(user,_User_P))
      end
  end.


parseRequest(Request)->
  [Fun, ArgsJSON]=string:split(Request,"\n\n"),
  FunA=list_to_atom(Fun),
  io:format("Parsed data: ~n~p~n~p~n",[FunA,ArgsJSON]),
  [FunA,ArgsJSON].

