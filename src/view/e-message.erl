%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. авг. 2022 16:21
%%%-------------------------------------------------------------------
-module('e-message').
-include("jsonerl/jsonerl.hrl").

-include("config.hrl").

-export([start/1,start/0]).

start(ConfPath)->
  register(e_message,self()),
  {ok,Text_Bin}=file:read_file(ConfPath),
  Conf=?json_to_record(config,Text_Bin),
  init(Conf).

start()->
  register(e_message,self()),
  {ok,Text_Bin}=file:read_file("priv/etc/config.json"),
  Conf=?json_to_record(config,Text_Bin),
  init(Conf).

init(#config{port = Port, acceptors_quantity = N})->
  case gen_tcp:listen(Port,[{active, false}]) of
    {ok,ListenSocket}->
      Con = start_repo(),
      AcceptorList = start_acceptors(N,ListenSocket,Con,[]),
      loop(AcceptorList,Con);
    {error,Reason}->
      io:format("FATAL e-message:init/1 Can't listen port.~n~p~n",[Reason]),
      exit(Reason)
  end.

loop(AcceptorList,Con)->ok.

%%вспомогательные функции
start_repo()->
  case (catch db:start_db()) of
    {ok,Con}->
      link(Con),
      Con;
    _ ->
      io:format("FATAL e-message:start_children/1 Repo can't start~n"),
      exit(repo_start_fail)
  end.

start_acceptors(0,_,_,Res)->
  Res;
start_acceptors(Num,ListenSocket,Con, Res)->
  case (catch spawn_link(acceptor,start,[ListenSocket,Con])) of
    {ok,PID}->
      start_acceptors(Num-1,ListenSocket,Con,[PID|Res]);
    _ ->
      start_acceptors(Num-1,ListenSocket,Con,Res)
  end.

