%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. июль 2022 11:23
%%%-------------------------------------------------------------------
-module(acceptor).
-include_lib("jsonerl/include/jsonerl.hrl").

-include_lib("e_message/include/entity.hrl").
-include_lib("e_message/include/request.hrl").
-include_lib("e_message/include/config.hrl").

%% API
-export([start/2]).

start(ListenSocket,Con)->
  %%init
  loop(ListenSocket,Con).

%%Перед принятием клиенсткой сессии акцептор ждёт
%%сигналы от супервизора, т.к. в этот момент он не занят обслуживанием клиента
%%если ничего не пришло, то акцептор встанет в очередь на обслуживание
loop(ListenSocket,Con)->
  receive
    {stop,From}->
      io:format("TRACE acceptor:loop/2. Received stop message~n"),
      From ! ok
  after
    500->
      case gen_tcp:accept(ListenSocket) of
        {ok, Socket} ->
          serve_connection(Socket,Con),
          loop(ListenSocket,Con);
        {error, Reason}->
          io:format("ERROR server:wait_request Socket ~w [~w] can't accept session. Reason:~p~n",[ListenSocket, self(),Reason])
      end
  end.

serve_connection(Socket,Con)->
  inet:setopts(Socket,[{active,once}]),
  receive
    {tcp,Socket,Request}->
      io:format("INFO server:loop/1 Socket ~w [~w] received request ~n", [Socket, self()]),
      serve_request(Socket,Request,Con),
      serve_connection(Socket,Con);
    {tcp_closed,Socket}->
      io:format("INFO server:loop/1 Socket ~w closed [~w]~n",[Socket,self()]),
      ok
  end.

time_millis()->
  round(erlang:system_time()/1.0e7).

%%обработка клиентских запросов
serve_request(Socket, Request,Con)->
  try
    [Fun,ArgsJSON]=parseRequest(Request),
    case Fun of
      create_user->
        create_user_handler(ArgsJSON,Socket,Con);
      delete_user->
        delete_user_handler(ArgsJSON,Socket,Con);
      create_dialogue->
        create_dialogue_handler(ArgsJSON,Socket,Con);
      get_dialogues->
        get_dialogues_handler(ArgsJSON,Socket,Con);
      quit_dialogue->
        quit_dialogue_handler(ArgsJSON,Socket,Con);
      send_message->
        send_message_handler(ArgsJSON,Socket,Con);
      get_message->
        get_message_handler(ArgsJSON,Socket,Con);
      get_messages->
        get_messages_handler(ArgsJSON,Socket,Con);
      read_message->
        read_message_handler(ArgsJSON,Socket,Con);
      change_text->
        change_text_handler(ArgsJSON,Socket,Con);
      delete_message->
        delete_message_handler(ArgsJSON,Socket,Con)
    end
  catch
    throw:{error,invalid_data} ->
      handle_error(invalid_data,Socket);
    throw:{error,_R}->
      handle_error(_R,Socket);
    error:{badmatch,Val}->
      io:format("ERROR acceptor:serve_request/3 Badmatch, Val:~p~n",[Val]),
      handle_error({error,critical_server_exception},Socket)
  end.

parseRequest(Request)->
  [Fun, ArgsJSON]=string:split(Request,"\n\n"),
  FunA=list_to_atom(Fun),
  io:format("TRACE server:parseRequest/1 Req data: ~n~p~n~p~n",[FunA,ArgsJSON]),
  [FunA,ArgsJSON].

%%обобщённый обработчик исключений
handle_error(_Reason, Socket)->
  Error = #error{type = error, msg = _Reason},
  ErrorMsg = ["error\n\n"|?record_to_json(error,Error)],
  gen_tcp:send(Socket,ErrorMsg).

%%обобщённый обработчик результатов запросов
%%Res - результат вызова контроллера, ради которого и совершался искомый запрос к серверу
%%HappyParse - callback-парсер, который превращает Erlang-терм в строку-ответ
%%Socket - сокет, по которому осуществляется связь с клиентом
handle_request_result(Res,HappyParse,Socket)->
  case Res of
    {error,_R}->
      handle_error(_R,Socket);
    OK->
      gen_tcp:send(Socket,["ok\n\n"|HappyParse(OK)])
  end.

%Пытается авторизовать пользователя.
%Если данные не валидны или пользователя нет в системе, то отправляется исключение
%throw:{error,not_authorised}
authorise(Nick,Pass,Con)->
  User = #user{nick=Nick,pass=Pass},
  try
    common_validation_service:check_object(User,user_validation_service:all()),
    user_controller:get_user(Nick,Pass,Con)
  catch
    throw:{error,invalid_data}->
      throw({error,not_authorised});
    throw:{error,not_found}->
      throw({error,not_authorised})
  end.

%%Ищет пользователя в базе для проведения авторизации.
%%В случае успеха возвращает true,
%%иначе - посылает клиенту ответ и возвращает false
is_authorised(Nick,Pass,_Socket,Con)->
  User = #user{nick=Nick,pass=Pass},
  case common_validation_service:is_object_valid(User,user_validation_service:all()) of
    true->
      U = user_controller:get_user(Nick,Pass,Con),
      case U of
        {error,_Reason}->
          false;
        []->
          false;
        _User->
          true
      end;
    false->
      false
    end.

create_user_handler(ArgsJSON, Socket, Con)->
  Args = ?json_to_record(create_user,ArgsJSON),
  #create_user{nick = Nick,pass = Pass} = Args,
  User = #user{nick = Nick,pass = Pass},
  common_validation_service:check_object(User,user_validation_service:all()),
  Res=user_controller:create_user(User, Con),
  handle_request_result(
    Res,
    fun(X)-> ?record_to_json(user,X) end,
    Socket).

create_dialogue_handler(ArgsJSON,Socket, Con)->
  Args = ?json_to_record(create_dialogue,ArgsJSON),
  #create_dialogue{nick = Nick, pass=Pass, name = Name, userNicks = UserNicks}=Args,
  D=#dialogue{name=Name,users = UserNicks},
  common_validation_service:check_object(D,dialogue_validation_service:all()),
  authorise(Nick,Pass,Con),
  Res=dialogue_controller:create_dialogue(D, Con),
  handle_request_result(Res,
                          fun(X)->?record_to_json(dialogue,X) end,
                          Socket).

get_dialogues_handler(ArgsJSON,Socket, Con)->
  Args=?json_to_record(get_dialogues,ArgsJSON),
  #get_dialogues{nick = Nick,pass = Pass}=Args,
  authorise(Nick,Pass,Con),
  _U=#user{nick = Nick,pass = Pass},
  Res=dialogue_controller:get_dialogues(_U, Con),
  io:format("TRACE server:get_dialogues_handler/3 D_LIST:~p~n",[Res]),
  handle_request_result(
    Res,
    fun(Y)-> parse:encodeRecordArray(Y,fun(X)->?record_to_json(dialogue,X) end) end,
    Socket).

quit_dialogue_handler(ArgsJSON,Socket, Con)->
  Args = ?json_to_record(quit_dialogue,ArgsJSON),
  #quit_dialogue{nick = Nick, pass = Pass, id=DID}=Args,
  common_validation_service:check_field(#dialogue{id=DID},
                                          dialogue_validation_service:all(),
                                          #dialogue.id),
  authorise(Nick,Pass,Con),
  _U=#user{nick = Nick,pass = Pass},
  D=dialogue_controller:get_dialogue(DID, Con),
  Res = dialogue_controller:quit_dialogue(D,_U, Con),
  if 
    is_record(Res,dialogue)->
      handle_request_result(
                Res,
                fun(X)->?record_to_json(dialogue,X) end,
                Socket);
    is_atom(Res)->
      handle_request_result(
                Res,
                fun(X)->atom_to_list(X) end,
                Socket)
  end.

send_message_handler(ArgsJSON, Socket, Con)->
  Args = ?json_to_record(send_message,ArgsJSON),
  #send_message{nick = Nick, pass = Pass, dialogueID = DID, text = Txt}=Args,
  io:format("TRACE acceptor:send_message_handler/3 Args:~p~n",[Args]),
  common_validation_service:check_field(#dialogue{id=DID},
                                          dialogue_validation_service:all(),
                                          #dialogue.id),
  common_validation_service:check_field(#message{text=Txt},
                                          message_validation_service:all(),
                                          #message.text),
  authorise(Nick,Pass,Con),
  D=dialogue_controller:get_dialogue(DID, Con),
  M=#message{from = Nick, text = Txt, timeSending = time_millis()},
  Res = dialogue_controller:add_message(D,M,Con),
  handle_request_result(Res,fun(X)-> ?record_to_json(message,X) end,Socket).

get_message_handler(ArgsJSON, Socket, Con)->
  Args = ?json_to_record(get_message,ArgsJSON),
  #get_message{nick = Nick,pass = Pass, messageID = MID, dialogueID = DID}=Args,
  common_validation_service:check_field(#message{id=MID},
                                          message_validation_service:all(),
                                          #message.id),
  common_validation_service:check_field(#dialogue{id=DID},
                                          dialogue_validation_service:all(),
                                          #dialogue.id),
  authorise(Nick,Pass,Con),
  handle_request_result(
        dialogue_controller:get_message(#user{nick=Nick},MID,DID,Con),
        fun(X)-> ?record_to_json(message,X) end,
        Socket).

get_messages_handler(ArgsJSON, Socket, Con)->
  Args = ?json_to_record(get_messages,ArgsJSON),
  #get_messages{nick = Nick, pass=Pass, id = DID}=Args,
  User = #user{nick=Nick,pass=Pass},
  common_validation_service:check_field(#dialogue{id=DID},
                                          dialogue_validation_service:all(),
                                          #dialogue.id),
  authorise(Nick,Pass,Con),
  D=dialogue_controller:get_dialogue(DID, Con),
  io:format("TRACE server:get_messages_handler/3 D:~p~n",[D]),
  Res = dialogue_controller:get_messages(User,D, Con),
  io:format("TRACE server:get_messages_handler/3 Messages:~p~n",[Res]),
  handle_request_result(
    Res,
    fun(Y)-> parse:encodeRecordArray(Y,fun(X)->?record_to_json(message,X) end) end,
    Socket).

read_message_handler(ArgsJSON,Socket, Con)->
  Args = ?json_to_record(read_message,ArgsJSON),
  #read_message{nick = Nick,pass = Pass, messageID=MID, dialogueID=DID}=Args,
  User = #user{nick=Nick,pass=Pass},
  common_validation_service:check_field(#message{id=MID},
                                          message_validation_service:all(),
                                          #message.id),
  common_validation_service:check_field(#dialogue{id=DID},
                                          dialogue_validation_service:all(),
                                          #dialogue.id),
  authorise(Nick,Pass,Con),
  M = dialogue_controller:get_message(User,MID,DID,Con),
  D = dialogue_controller:get_dialogue(DID,Con),
  Res = dialogue_controller:read_message(#user{nick=Nick},M,D,Con),
  handle_request_result(Res,
                          fun(X)-> ?record_to_json(message,X) end,
                          Socket).

change_text_handler(ArgsJSON,Socket, Con)->
  Args = ?json_to_record(change_text,ArgsJSON),
  #change_text{nick = Nick,pass = Pass,messageID=MID, dialogueID=DID,text = Text}=Args,
  User = #user{nick=Nick,pass=Pass},
  common_validation_service:check_field(#message{id=MID},
                                          message_validation_service:all(),
                                          #message.id),
  common_validation_service:check_field(#dialogue{id=DID},
                                          dialogue_validation_service:all(),
                                          #dialogue.id),
  common_validation_service:check_field(#message{text=Text},
                                          message_validation_service:all(),
                                          #message.text),
  authorise(Nick,Pass,Con),
  M = dialogue_controller:get_message(User,MID,DID,Con),
  Res = dialogue_controller:change_text(User,M,Text,Con),
  handle_request_result(
    Res,
    fun(X)-> ?record_to_json(message,X) end,
    Socket).

delete_message_handler(ArgsJSON,Socket, Con)->
  Args = ?json_to_record(delete_message,ArgsJSON),
  #delete_message{nick = Nick,pass = Pass,messageID = MID, dialogueID = DID}=Args,
  common_validation_service:check_field(#message{id=MID},
                                          message_validation_service:all(),
                                          #message.id),
  common_validation_service:check_field(#dialogue{id=DID},
                                          dialogue_validation_service:all(),
                                          #dialogue.id),
  authorise(Nick,Pass,Con),
  User = #user{nick = Nick,pass = Pass},
  M=dialogue_controller:get_message(User,MID,DID,Con),
  D=dialogue_controller:get_dialogue(DID, Con),
  io:format("TRACE server:delete_message_handler/3 D: ~p~n",[D]),
  Res = dialogue_controller:delete_message(D,M,User,Con),
  handle_request_result(
    Res,
    fun(X)->atom_to_list(X) end,
    Socket).

delete_user_handler(ArgsJSON,Socket,Con)->
  Args = ?json_to_record(delete_user,ArgsJSON),
  #delete_user{nick = Nick,pass = Pass} = Args,
  User = #user{nick = Nick,pass = Pass},
  common_validation_service:check_object(User,user_validation_service:all()),
  Res = user_controller:delete_user(User, Con),
  handle_request_result(
    Res,
    fun(X)-> atom_to_list(X) end,
    Socket).