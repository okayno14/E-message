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
      create_user_handler(ArgsJSON,Socket);
    create_dialogue->
      create_dialogue_handler(ArgsJSON,Socket)
  end.

parseRequest(Request)->
  [Fun, ArgsJSON]=string:split(Request,"\n\n"),
  FunA=list_to_atom(Fun),
  io:format("Parsed data: ~n~p~n~p~n",[FunA,ArgsJSON]),
  [FunA,ArgsJSON].

handle_error(_Reason, Socket)->
  ErrorMsg = #error{type = error, msg = _Reason},
  gen_tcp:send(Socket,?record_to_json(error,ErrorMsg)).

%%Ищет пользователя в базе для проведения авторизации.
%%В случае успеха возвращает true,
%%иначе - посылает клиенту ответ и возвращает false
is_authorised(Nick,Pass,Socket)->
  case user_controller:get_user(Nick,Pass) of
    {error,_Reason}->
      handle_error(_Reason,Socket),
      false;
    []->
      handle_error(not_authorized,Socket),
      false;
    _User->
      true
  end.

create_user_handler(ArgsJSON, Socket)->
  Args = ?json_to_record(create_user,ArgsJSON),
  #create_user{nick = Nick,pass = Pass} = Args,
  User = #user{nick = Nick,pass = Pass},
  case user_controller:create_user(User) of
    {error,_Reason}->
      handle_error(_Reason,Socket);
    _User_P->
      gen_tcp:send(Socket,?record_to_json(user,_User_P))
  end.

create_dialogue_handler(ArgsJSON,Socket)->
  Args = ?json_to_record(create_dialogue,ArgsJSON),
  #create_dialogue{nick = Nick, pass=Pass, name = Name, userNicks = UserNicks}=Args,
  case is_authorised(Nick,Pass,Socket) of
    true->
      _D=#dialogue{name=Name,users = UserNicks},
      Res=dialogue_controller:create_dialogue(_D),
      case Res of
        {error,_Reason1} -> handle_error(_Reason1,Socket);
        _D_P->gen_tcp:send(Socket,?record_to_json(dialogue,_D_P))
      end;
    _->false
  end.

%%get_dialogues_handler(ArgsJSON,Socket)->
%%    Args= ?json_to_record(get_dialogues,ArgsJSON),
%%    #get_dialogues{nick = Nick,pass = Pass}=Args,
%%    case is_authorised(Nick,Pass,Socket) of
%%      true->
%%        _U=#user{nick = Nick,pass = Pass},
%%        Res=dialogue_controller:get_dialogues(_U),
%%        case Res of
%%          {error,_Reason1}-> handle_error(_Reason1,Socket);
%%          _D
%%        end
%%    end


