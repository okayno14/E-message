%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. авг. 2022 16:21
%%%-------------------------------------------------------------------
-module(e_message).
-include("jsonerl/jsonerl.hrl").

-include("config.hrl").

-export([start/1,start/0]).

start(ConfPath)->
  Me = self(),
  io:format("INFO e-message:start/1. E-message started. Root_pid = ~p~n",[Me]),
  register(e_message,Me),
  {ok,Text_Bin}=file:read_file(ConfPath),
  Conf=?json_to_record(config,Text_Bin),
  init(Conf).

start()->
  Me = self(),
  io:format("INFO e-message:start/1. E-message started. Root_pid = ~p~n",[Me]),
  register(e_message,Me),
  {ok,Text_Bin}=file:read_file("priv/etc/config.json"),
  Conf=?json_to_record(config,Text_Bin),
  init(Conf).

init(#config{port = Port, acceptors_quantity = N})->
  process_flag(trap_exit, true),
  case gen_tcp:listen(Port,[{active, false}]) of
    {ok,ListenSocket}->
      Con = start_repo(),
      AcceptorList = start_acceptors(N,ListenSocket,Con,[]),
      loop(AcceptorList,ListenSocket,Con);
    {error,Reason}->
      io:format("FATAL e-message:init/1 Can't listen port.~n~p~n",[Reason]),
      exit(Reason)
  end.

loop(AcceptorList,ListenSocket,Con)->
  receive
    {'EXIT',PID,_Reason}->
      if
        Con =:= PID ->
          io:format("WARNING e-message:loop/3. Proccess-repo ~p falls. Reason:~p~n",[PID,_Reason]),
          loop(AcceptorList,ListenSocket,start_repo());
        Con =/= PID ->
          io:format("WARNING e-message:loop/3. Proccess-acceptor ~p falls. Reason:~p~n",[PID,_Reason]),
          AcceptorList_N=restart_acceptor(PID,ListenSocket,Con,AcceptorList),
          loop(AcceptorList_N,ListenSocket,Con)
      end;
    {stop, From}->
      terminate_children(AcceptorList,Con),
      From ! ok
  end.

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
start_acceptors(Num,ListenSocket,Con,Res)->
  case (catch start_acceptor(ListenSocket,Con)) of
    {ok,PID}->
      io:format("INFO e-message:start_acceptors/4 Acceptor#~w PID:~p spawned~n",[Num,PID]),
      start_acceptors(Num-1,ListenSocket,Con,[PID|Res]);
    _ ->
      start_acceptors(Num-1,ListenSocket,Con,Res)
  end.

start_acceptor(ListenSocket,Con)->
  {ok,spawn_link(acceptor,start,[ListenSocket,Con])}.

restart_acceptor(PID,ListenSocket,Con,AcceptorList)->
  Fun =
    fun(Elem, Res)->
      if
        Elem =/= PID ->
          Res;
        Elem =:= PID ->
          {ok,PID_N}=start_acceptor(ListenSocket,Con),
          [PID_N|Res]
      end
    end,
  lists:foldl(Fun,[],AcceptorList).

%%пока что сервер с БД просто убивается
terminate_children([],Con)->
  exit(Con,kill);
%%Число взял с потолка
terminate_children([PID,Tail],Con)->
  PID ! {stop,self()},
  receive
    ok ->
      terminate_children(Tail,Con)
    after
      50000->
        exit(PID,kill)
  end.