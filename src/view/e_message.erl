%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. авг. 2022 16:21
%%%-------------------------------------------------------------------
-module(e_message).
-include_lib("jsonerl/include/jsonerl.hrl").

-include_lib("e_message/include/config.hrl").
-include_lib("e_message/include/entity.hrl").

-export([start/0,
        start/1,
        init/1]).

start(ConfPath)->
  start_observer(parse_conf(ConfPath)).

start()->
  start_observer(parse_conf("priv/etc/config.json")).

init(#config{db_domain=DB_Domain,
            db_user=DB_U,
            db_pass=DB_PASS,
            db=DB,
            db_port=DB_PORT,
            port = Port, 
            acceptors_quantity = N}=Config)->
  process_flag(trap_exit, true),
  case gen_tcp:listen(Port,[{active, false}]) of
    {ok,ListenSocket}->
      Repo = start_repo(DB_Domain,DB_PORT,DB,DB_U,DB_PASS),
      case Repo of
        {ok,Con}->
          io:format("INFO e-message:init/1 Repo started ~p~n",[Con]),
          link(Con),
          Con,
          AcceptorList = start_acceptors(N,ListenSocket,Con,[]),
          loop(AcceptorList,ListenSocket,Con,Config);
        _ ->
          io:format("FATAL e-message:init/1 Repo can't start~n"),
          terminate_socket(ListenSocket),
          exit(repo_start_fail)
      end;
    {error,Reason}->
      io:format("FATAL e-message:init/1 Can't listen port.~n~p~n",[Reason]),
      exit(Reason)
  end.

loop(AcceptorList,ListenSocket,Con,
      #config{db_domain=DB_Domain,
      db_user=DB_U,
      db_pass=DB_PASS,
      db=DB,
      db_port=DB_PORT}=Config)->
  io:format("TRACE e_mesage:loop/3. AcceptorList:~p~n",[AcceptorList]),
  receive
    {'EXIT',PID,_Reason}->
      if
        %упала база
        Con =:= PID ->
          io:format("WARNING e-message:loop/3. Proccess-repo ~p falls. Reason:~p~n",[PID,_Reason]),
          case start_repo(DB_Domain,DB_PORT,DB,DB_U,DB_PASS) of
            {ok,Con1}->
              loop(AcceptorList,ListenSocket,Con1,Config);
            _ ->
              terminate_children(AcceptorList),
              terminate_socket(ListenSocket)
          end;
        %упал другой процесс
        Con =/= PID ->
          io:format("WARNING e-message:loop/3. Proccess-acceptor ~p falls. Reason:~p~n",[PID,_Reason]),
          AcceptorList_N=restart_acceptor(PID,ListenSocket,Con,AcceptorList),
          loop(AcceptorList_N,ListenSocket,Con, Config)
      end;
    {stop, From}->
      io:format("TRACE e-message:loop/3. Received stop-message from ~p~n",[From]),
      free_resources(AcceptorList,ListenSocket,Con),
      io:format("TRACE e-message:loop/3. STOP. Sending answer~n"),
      From ! ok
  end.

%%вспомогательные функции
parse_conf(ConfPath)->
  {ok,Text_Bin}=file:read_file(ConfPath),
  Rec = ?json_to_record(config,Text_Bin),
  parse:rec_binairies_to_lists(Rec).
  

start_observer(Conf)->
  Me = self(),
  io:format("INFO e-message:start/1. E-message started. Root_pid = ~p~n",[Me]),
  register(e_message,spawn_link(?MODULE,init,[Conf])),
  ok.

start_repo(Domain,Port,Database,User,Pass)->
  io:format("TRACE e_message:start_repo/5 Database options:~n~p ~p ~p ~p ~p~n",[Domain,Port,Database,User,Pass]),
  catch db:start_db(Domain,Port,Database,User,Pass).

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
  {ok,spawn_link(acceptor, start,[ListenSocket,Con])}.

restart_acceptor(PID,ListenSocket,Con,AcceptorList)->
  Fun =
    fun(Elem, Res)->
      if
        Elem =/= PID ->
          [Elem|Res];
        Elem =:= PID ->
          {ok,PID_N}=start_acceptor(ListenSocket,Con),
          io:format("TRACE e_message:restart_acceptor. Acceptor#~w replaced by Acceptor#~w~n",[PID,PID_N]),
          [PID_N|Res]
      end
    end,
  lists:foldl(Fun,[],AcceptorList).

%%пока что сервер с БД просто убивается
terminate_children([])->
  ok;
%%Число взял с потолка
terminate_children([PID|Tail])->
  io:format("INFO e_message:terminate_children. Trying stop child ~p~n",[PID]),
  PID ! {stop,self()},
  receive
    ok ->
      terminate_children(Tail)
    after
      5000->
        io:format("INFO e_message:terminate_children. Child ~p won't stop. Sending kill~n",[PID]),
        exit(PID,kill),
        terminate_children(Tail)
  end.

terminate_repo(Con)->
  io:format("INFO e_message:terminate_children. Sending kill to Repo~n"),
  exit(Con,kill).

terminate_socket(ListenSocket)->
  io:format("INFO e_message:terminate_socket. Socket ~p closed~n",[ListenSocket]),
  gen_tcp:close(ListenSocket).

free_resources(AcceptorList,ListenSocket,Con)->
  terminate_children(AcceptorList),
  terminate_repo(Con),
  terminate_socket(ListenSocket).