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
      io:format("INFO server:start/0 Server started. Port=~w~n",[5560]),
      start_servers(8,ListenSocket),
      io:format("INFO server:start/0 Started ~w acceptors~n",[8]),
      %%замораживает listen-процесс
      timer:sleep(infinity);
    {error, Reason}->
      io:format("FATAL Can't listen port.~n~p~n",[Reason])
  end.

start_servers(0,_)-> ok;
start_servers(Num, ListenSocket)->
  spawn(?MODULE,wait_request,[ListenSocket]),
  io:format("INFO server:start_servers/2 Acceptor#~w spawned~n",[Num]),
  start_servers(Num-1,ListenSocket).

wait_request(ListenSocket)->
  case gen_tcp:accept(ListenSocket) of
    {ok, Socket} ->
      loop(Socket),
      wait_request(ListenSocket);
    {error, Reason}->
      io:format("ERROR server:wait_request Socket ~w [~w] can't accept session. Reason:~p~n",[ListenSocket, self(),Reason])
  end.

%%функция-цикл работы потока-акцептора
loop(Socket)->
  inet:setopts(Socket,[{active,once}]),
  receive
    {tcp,Socket,Request}->
      io:format("INFO server:loop/1 Socket ~w [~w] received request ~n", [Socket, self()]),
      process_request(Socket,Request),
      loop(Socket);
    {tcp_closed,Socket}->
      io:format("INFO server:loop/1 Socket ~w closed [~w]~n",[Socket,self()]),
      ok
  end.

time_millis()->
  round(erlang:system_time()/1.0e4).

%%обработка клиентских запросов
process_request(Socket, Request)->
  [Fun,ArgsJSON]=parseRequest(Request),
  case Fun of
    create_user->
      create_user_handler(ArgsJSON,Socket);
    create_dialogue->
      create_dialogue_handler(ArgsJSON,Socket);
    get_dialogues->
      get_dialogues_handler(ArgsJSON,Socket);
    quit_dialogue->
      quit_dialogue_handler(ArgsJSON,Socket);
    send_message->
      send_message_handler(ArgsJSON,Socket)
  end.

parseRequest(Request)->
  [Fun, ArgsJSON]=string:split(Request,"\n\n"),
  FunA=list_to_atom(Fun),
  io:format("TRACE server:parseRequest/1 Req data: ~n~p~n~p~n",[FunA,ArgsJSON]),
  [FunA,ArgsJSON].

%%обобщённый обработчик исключений
handle_error(_Reason, Socket)->
  ErrorMsg = #error{type = error, msg = _Reason},
  gen_tcp:send(Socket,?record_to_json(error,ErrorMsg)).

%%обобщённый обработчик результатов запросов
%%Res - результат вызова контроллера, ради которого и совершался искомый запрос к серверу
%%HappyParse - callback-парсер, который превращает Erlang-терм в строку-ответ
%%Socket - сокет, по которому осуществляется связь с клиентом
handle_request_result(Res,HappyParse,Socket)->
  case Res of
    {error,_R}->handle_error(_R,Socket);
    OK->gen_tcp:send(Socket,HappyParse(OK))
  end.

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
  Res=user_controller:create_user(User),
  handle_request_result(
    Res,
    fun(X)-> ?record_to_json(user,X) end,
    Socket).

create_dialogue_handler(ArgsJSON,Socket)->
  Args = ?json_to_record(create_dialogue,ArgsJSON),
  #create_dialogue{nick = Nick, pass=Pass, name = Name, userNicks = UserNicks}=Args,
  case is_authorised(Nick,Pass,Socket) of
    true->
      _D=#dialogue{name=Name,users = UserNicks},
      Res=dialogue_controller:create_dialogue(_D),
      handle_request_result(Res,
        fun(X)->?record_to_json(dialogue,X) end,
        Socket);
    false->
      handle_error(not_authorised,Socket)
  end.

get_dialogues_handler(ArgsJSON,Socket)->
  Args= ?json_to_record(get_dialogues,ArgsJSON),
  #get_dialogues{nick = Nick,pass = Pass}=Args,
  case is_authorised(Nick,Pass,Socket) of
    true->
      _U=#user{nick = Nick,pass = Pass},
      Res=dialogue_controller:get_dialogues(_U),
      handle_request_result(
        Res,
        fun(Y)->parse:encodeRecordArray(Y,fun(X)->?record_to_json(dialogue,X) end) end,
        Socket);
    false->
      handle_error(not_authorised,Socket)
  end.

quit_dialogue_handler(ArgsJSON,Socket)->
  Args = ?json_to_record(quit_dialogue,ArgsJSON),
  #quit_dialogue{nick = Nick, pass = Pass, id=DID}=Args,
  io:format("TRACE server:quit_dialogue_handler/2 parsed User:~p ~p~n",[Nick,Pass]),
  io:format("TRACE server:quit_dialogue_handler/2 parsed dialID: ~p~n",[DID]),
  case is_authorised(Nick,Pass,Socket) of
    true->
      io:format("TRACE server:quit_dialogue_handler/2 User authorised~n"),
      _U=#user{nick = Nick,pass = Pass},
      D=dialogue_controller:get_dialogue(DID),
      io:format("TRACE server:quit_dialogue_handler/2 Finded Dialogue:~p~n",[D]),
      case D of
        {error,_R}->
          handle_error(_R,Socket);
        D->
          Res = dialogue_controller:quit_dialogue(D,_U),
          handle_request_result(
            Res,
            fun(X)->atom_to_list(X) end,
            Socket)
      end;
    false->
      io:format("TRACE server:quit_dialogue_handler/2 User not_authorised~n"),
      handle_error(not_authorised,Socket)
  end.

send_message_handler(ArgsJSON, Socket)->
  Args = ?json_to_record(send_message,ArgsJSON),
  #send_message{nick = Nick, pass = Pass, dialogueID = DID, text = Txt}=Args,
  io:format("TRACE server:send_message_handler/2 parsed dialID: ~p~n",[DID]),
  case is_authorised(Nick,Pass,Socket) of
    true->
      io:format("INFO server:send_message_handler/2 User authorised.~n"),
      D=dialogue_controller:get_dialogue(DID),
      io:format("TRACE server:send_message_handler/2 Finded Dialogue:~p~n",[D]),
      case D of
        {error,_R}->
          handle_error(_R,Socket);
        D->
          M=#message{from = Nick, text = Txt, timeSending = time_millis()},
          Res = dialogue_controller:add_message(D,M),
          io:format("TRACE server:send_message_handler/2 Controller's res:~p~n",[Res]),
          handle_request_result(Res,fun(X)-> ?record_to_json(message,X) end,Socket)
      end;
    false->ok
  end.