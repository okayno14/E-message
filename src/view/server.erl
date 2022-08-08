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
-include("config.hrl").
%% API
-export([start/0,
        start_acceptor/2,
        time_millis/0,
        parseRequest/1]).

start() ->
  {ok,Con}=eredis:start_link(),
  {ok,Text_Bin}=file:read_file("priv/etc/config.json"),
  Conf=?json_to_record(config,Text_Bin),
  #config{port = Port,acceptors_quantity = N}=Conf,
  case  gen_tcp:listen(Port,[{active, false}]) of
    {ok, ListenSocket}->
      io:format("INFO server:start/0 Server started. Port=~w~n",[Port]),
      start_servers(N,ListenSocket,Con),
      io:format("INFO server:start/0 Started ~w acceptors~n",[N]),
      %%замораживает listen-процесс
      timer:sleep(infinity);
    {error, Reason}->
      io:format("FATAL Can't listen port.~n~p~n",[Reason])
  end.

start_servers(0,_,_)-> ok;
start_servers(Num, ListenSocket,Con)->
  spawn(?MODULE,start_acceptor,[ListenSocket,Con]),
  io:format("INFO server:start_servers/2 Acceptor#~w spawned~n",[Num]),
  start_servers(Num-1,ListenSocket,Con).

start_acceptor(ListenSocket,Con)->
  case gen_tcp:accept(ListenSocket) of
    {ok, Socket} ->
      loop(Socket,Con),
      start_acceptor(ListenSocket,Con);
    {error, Reason}->
      io:format("ERROR server:wait_request Socket ~w [~w] can't accept session. Reason:~p~n",[ListenSocket, self(),Reason])
  end.

%%функция-цикл работы потока-акцептора
loop(Socket,Con)->
  inet:setopts(Socket,[{active,once}]),
  receive
    {tcp,Socket,Request}->
      io:format("INFO server:loop/1 Socket ~w [~w] received request ~n", [Socket, self()]),
      process_request(Socket,Request,Con),
      loop(Socket,Con);
    {tcp_closed,Socket}->
      io:format("INFO server:loop/1 Socket ~w closed [~w]~n",[Socket,self()]),
      ok
  end.

time_millis()->
  round(erlang:system_time()/1.0e7).

%%обработка клиентских запросов
process_request(Socket, Request,Con)->
  [Fun,ArgsJSON]=parseRequest(Request),
  case Fun of
    create_user->
      create_user_handler(ArgsJSON,Socket, Con);
    create_dialogue->
      create_dialogue_handler(ArgsJSON,Socket, Con);
    get_dialogues->
      get_dialogues_handler(ArgsJSON,Socket, Con);
    quit_dialogue->
      quit_dialogue_handler(ArgsJSON,Socket, Con);
    send_message->
      send_message_handler(ArgsJSON,Socket, Con);
    get_message->
      get_message_handler(ArgsJSON,Socket, Con);
    get_messages->
      get_messages_handler(ArgsJSON,Socket, Con);
    read_message->
      read_message_handler(ArgsJSON,Socket, Con);
    change_text->
      change_text_handler(ArgsJSON,Socket, Con);
    delete_message->
      delete_message_handler(ArgsJSON,Socket, Con)
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
is_authorised(Nick,Pass,Socket,Con)->
  case user_controller:get_user(Nick,Pass,Con) of
    {error,_Reason}->
      handle_error(_Reason,Socket),
      false;
    []->
      handle_error(not_authorized,Socket),
      false;
    _User->
      true
  end.

create_user_handler(ArgsJSON, Socket, Con)->
  Args = ?json_to_record(create_user,ArgsJSON),
  #create_user{nick = Nick,pass = Pass} = Args,
  User = #user{nick = Nick,pass = Pass},
  Res=user_controller:create_user(User, Con),
  handle_request_result(
    Res,
    fun(X)-> ?record_to_json(user,X) end,
    Socket).

create_dialogue_handler(ArgsJSON,Socket, Con)->
  Args = ?json_to_record(create_dialogue,ArgsJSON),
  #create_dialogue{nick = Nick, pass=Pass, name = Name, userNicks = UserNicks}=Args,
  case is_authorised(Nick,Pass,Socket, Con) of
    true->
      _D=#dialogue{name=Name,users = UserNicks},
      Res=dialogue_controller:create_dialogue(_D, Con),
      handle_request_result(Res,
        fun(X)->?record_to_json(dialogue,X) end,
        Socket);
    false->
      handle_error(not_authorised,Socket)
  end.

get_dialogues_handler(ArgsJSON,Socket, Con)->
  Args= ?json_to_record(get_dialogues,ArgsJSON),
  #get_dialogues{nick = Nick,pass = Pass}=Args,
  case is_authorised(Nick,Pass,Socket, Con) of
    true->
      _U=#user{nick = Nick,pass = Pass},
      Res=dialogue_controller:get_dialogues(_U, Con),
      io:format("TRACE server:get_dialogues_handler/3 D_LIST:~p~n",[Res]),
      handle_request_result(
        Res,
        fun(Y)-> parse:encodeRecordArray(Y,fun(X)->?record_to_json(dialogue,X) end) end,
        Socket);
    false->
      handle_error(not_authorised,Socket)
  end.

quit_dialogue_handler(ArgsJSON,Socket, Con)->
  Args = ?json_to_record(quit_dialogue,ArgsJSON),
  #quit_dialogue{nick = Nick, pass = Pass, id=DID}=Args,
  io:format("TRACE server:quit_dialogue_handler/2 parsed User:~p ~p~n",[Nick,Pass]),
  io:format("TRACE server:quit_dialogue_handler/2 parsed dialID: ~p~n",[DID]),
  case is_authorised(Nick,Pass,Socket, Con) of
    true->
      io:format("TRACE server:quit_dialogue_handler/2 User authorised~n"),
      _U=#user{nick = Nick,pass = Pass},
      D=dialogue_controller:get_dialogue(DID, Con),
      io:format("TRACE server:quit_dialogue_handler/2 Finded Dialogue:~p~n",[D]),
      case D of
        {error,_R}->
          handle_error(_R,Socket);
        D->
          Res = dialogue_controller:quit_dialogue(D,_U, Con),
          handle_request_result(
            Res,
            fun(X)->atom_to_list(X) end,
            Socket)
      end;
    false->
      io:format("TRACE server:quit_dialogue_handler/2 User not_authorised~n"),
      handle_error(not_authorised,Socket)
  end.

send_message_handler(ArgsJSON, Socket, Con)->
  Args = ?json_to_record(send_message,ArgsJSON),
  #send_message{nick = Nick, pass = Pass, dialogueID = DID, text = Txt}=Args,
  io:format("TRACE server:send_message_handler/2 parsed dialID: ~p~n",[DID]),
  case is_authorised(Nick,Pass,Socket, Con) of
    true->
      io:format("INFO server:send_message_handler/2 User authorised.~n"),
      D=dialogue_controller:get_dialogue(DID, Con),
      io:format("TRACE server:send_message_handler/2 Finded Dialogue:~p~n",[D]),
      case D of
        {error,_R}->
          handle_error(_R,Socket);
        D->
          M=#message{from = Nick, text = Txt, timeSending = time_millis()},
          io:format("TRACE server:send_message_handler/2 Written Message:~p~n",[M]),
          Res = dialogue_controller:add_message(D,M,Con),
          io:format("TRACE server:send_message_handler/2 Controller's res:~p~n",[Res]),
          handle_request_result(Res,fun(X)-> ?record_to_json(message,X) end,Socket)
      end;
    false->ok
  end.

get_message_handler(ArgsJSON, Socket, Con)->
  Args = ?json_to_record(get_message,ArgsJSON),
  #get_message{nick = Nick,pass = Pass, id = MID}=Args,
  case is_authorised(Nick,Pass,Socket, Con) of
    true->
      handle_request_result(
        dialogue_controller:get_message(MID, Con),
        fun(X)-> ?record_to_json(message,X) end,
        Socket);
    false->
      ok
  end.

get_messages_handler(ArgsJSON, Socket, Con)->
  Args = ?json_to_record(get_messages,ArgsJSON),
  #get_messages{nick = Nick, pass=Pass, id = DID}=Args,
  case is_authorised(Nick,Pass,Socket, Con) of
    true->
      D=dialogue_controller:get_dialogue(DID, Con),
      io:format("TRACE server:get_messages_handler/3 D:~p~n",[D]),
      case D of
        {error,_R}->
          handle_error(_R,Socket);
        D->
          Res = dialogue_controller:get_messages(D, Con),
          io:format("TRACE server:get_messages_handler/3 Messages:~p~n",[Res]),
          handle_request_result(
            Res,
            fun(Y)-> parse:encodeRecordArray(Y,fun(X)->?record_to_json(message,X) end) end,
            Socket)
      end;
    false->ok
  end.

read_message_handler(ArgsJSON,Socket, Con)->
  Args = ?json_to_record(read_message,ArgsJSON),
  #read_message{nick = Nick,pass = Pass, id = MID}=Args,
  case is_authorised(Nick,Pass,Socket, Con) of
    true->
      case dialogue_controller:get_message(MID, Con) of
        {error,_R}->
          handle_error(_R,Socket);
        M->
          Res = dialogue_controller:read_message(M, Con),
          handle_request_result(
            Res,
            fun(X)-> ?record_to_json(message,X) end,
            Socket)
      end;
    false->ok
  end.

change_text_handler(ArgsJSON,Socket, Con)->
  Args = ?json_to_record(change_text,ArgsJSON),
  #change_text{nick = Nick,pass = Pass,id=MID,text = Text}=Args,
  case is_authorised(Nick,Pass,Socket, Con) of
    true->
      case dialogue_controller:get_message(MID, Con) of
        {error,_R}->
          handle_error(_R,Socket);
        M->
          Res = dialogue_controller:change_text(M,Text, Con),
          handle_request_result(
            Res,
            fun(X)-> ?record_to_json(message,X) end,
            Socket)
      end;
    false->ok
  end.

delete_message_handler(ArgsJSON,Socket, Con)->
  Args = ?json_to_record(delete_message,ArgsJSON),
  #delete_message{nick = Nick,pass = Pass,messageID = MID, dialogueID = DID}=Args,
  case is_authorised(Nick,Pass,Socket, Con) of
    true->
      User = #user{nick = Nick,pass = Pass},
      M=dialogue_controller:get_message(MID, Con),
      D=dialogue_controller:get_dialogue(DID, Con),
      io:format("TRACE server:delete_message_handler/3 D: ~p~n",[D]),
      if
        is_record(M,message) and is_record(D,dialogue)->
          Res = dialogue_controller:delete_message(D,M,User, Con),
          handle_request_result(
            Res,
            fun(X)->atom_to_list(X) end,
            Socket);
        element(1,M)=:=error->
          handle_error(element(2,M),Socket);
        element(1,D)=:=error->
          handle_error(element(2,D),Socket)
      end,
      ok;
    false->ok
  end.
