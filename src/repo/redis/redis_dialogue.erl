%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. авг. 2022 10:21
%%%-------------------------------------------------------------------
-module(redis_dialogue).
-include("entity.hrl").
-include("jsonerl/jsonerl.hrl").
-export([write/2,
        read/2,
        read_by_user/2,
        fetch_messages/2,
        update/2,
        delete/2]).

%% на вход всегда принимаются:
%%     дескриптор соединения, сущность
%%     дескриптор соединения, ключи поиска

%%create-операции должны возвращать 1 персистентный объект
%%read-операции - фильтры, поэтому они возвращают пустой или заполненный список
%%update-операции - возвращают новый объект
%%delete - ok

%%записать пользователей
%%записать метаданные диалога
write(Con,#dialogue{users = Nicks} = Dialogue)->
  {ok, DID} = eredis:q(Con,["INCR", "SeqDial"]),
  DID_Num = binary_to_integer(DID),
  %%Специально зануляю коллекцию ников, так как эта информация будет храниться в множестве
  Commited = Dialogue#dialogue{id=DID_Num, users = []},

  eredis:q(Con,["MULTI"]),
    {ok,_} = eredis:q(Con,["HSET",atom_to_list(dialogue),DID_Num,?record_to_json(dialogue,Commited)]),
    write_users(Con, Commited, Nicks),
  {ok,_}=eredis:q(Con,["EXEC"]),

  Dialogue#dialogue{id = DID_Num}.

%%прочитать пользователей ok
%%прочитать сообщения ok.
%% Сообщения читаются в обратном порядке, чтобы при обходе сообщений они вернулись в правильной временной последовательности
read(Con, DID) when is_integer(DID)->
  {ok, T} = eredis:q(Con,["HGET",atom_to_list(dialogue),DID]),
  case T of
    undefined->[];
    JSON ->
      Dialogue = ?json_to_record(dialogue,JSON),
      {ok,Users} = eredis:q(Con,["SMEMBERS", name_gen:gen_dialogue_user_name(Dialogue)]),
      {ok,Messages} = eredis:q(Con,["ZREVRANGE",name_gen:gen_dialogue_message_name(Dialogue),0,-1]),
      [Dialogue#dialogue{id = DID,
                        users = Users,
                        messages=lists:map(fun(MID_JSON)->binary_to_integer(MID_JSON) end,
                                          Messages)}]
  end.

read_by_user(Con,#user{nick = Nick})->
  %%получаем список множеств участников диалогов
  {ok,Sets} = eredis:q(Con,["KEYS",name_gen:gen_dialogue_user_search_pattern()]),
  io:format("TRACE redis_dialogue:read_by_user/2 Sets=~p~n",[Sets]),
  %%определяем функцию заполнения результата текущей функции
  Fun =
    fun(Set_Nicks, Res)->
      {ok,IsContain} = eredis:q(Con,["SISMEMBER", Set_Nicks, Nick]),
      case binary_to_integer(IsContain) of
        0->
          Res;
        1->
          %%Если попали сюда, значит, в текущем множестве участников есть искомый пользователь
          %%Извлекаем из имени множества идентификатор диалога
          {ok,DID} = name_gen:parse_DID_from_dialogue_message(Set_Nicks),
          %%Запрашиваем диалог по идентификатору
          [Dialogue|_]=read(Con,DID),
          %%Добавляем диалог в результирующий список
          [Dialogue|Res]
      end
    end,
  lists:foldl(Fun,[],Sets).

fetch_messages(Con,#dialogue{messages = Messages})->
  Fun=
    fun(MID,Res)->
      {ok, M}=eredis:q(Con,["HGET", atom_to_list(message),MID]),
      [?json_to_record(message,M)|Res]
    end,
  lists:foldl(Fun,[],Messages).

%%переписать сообщения
%%переписать пользователей
%%переписать метаданные диалога
update(Con,#dialogue{users = Nicks, messages = MID_LIST, id=DID}=Dialogue)->
  %%Получить сообщения. Нужно для rewrite_messages.
  %%Действие проводится вне указанной функции, т.к. eredis не позволяет читать данные внутри транзакций
  {ok,M_ListJSON} = eredis:q(Con,["HMGET",atom_to_list(message)|MID_LIST]),
  io:format("TRACE redis:dialogue/2 M_ListJSON: ~p~n",[M_ListJSON]),
  eredis:q(Con,["MULTI"]),
    rewrite_messages(Con,Dialogue,M_ListJSON),
    eredis:q(Con,["DEL",name_gen:gen_dialogue_user_name(Dialogue)]),
    write_users(Con,Dialogue,Nicks),
    Commited = Dialogue#dialogue{id=DID, users = [],messages = []},
    {ok,_} = eredis:q(Con,["HSET",atom_to_list(dialogue),DID,?record_to_json(dialogue,Commited)]),
  {ok,T}=eredis:q(Con,["EXEC"]),
  io:format("TRACE redis:update/2 Transaction res: ~p~n",[T]),
  Dialogue.

delete(Con,#dialogue{messages = Messages, id = DID}=Dialogue)->
  eredis:q(Con,["MULTI"]),
    %%удаление множества участников диалога
    eredis:q(Con,["DEL",name_gen:gen_dialogue_user_name(Dialogue)]),
    %%удаление дерева сообщений диалога
    eredis:q(Con,["DEL",name_gen:gen_dialogue_message_name(Dialogue)]),
    %%каскадное удаление связанных сообщений
    Fun =
      fun(MID)->
        eredis:q(Con, ["HDEL",atom_to_list(message),MID])
      end,
    lists:map(Fun,Messages),
    eredis:q(Con,["HDEL",atom_to_list(dialogue),DID]),
  {ok,_}=eredis:q(Con,["EXEC"]),
  ok.

%%PRIVATE-функции

%%DID - бинарная строка, в которой записан численный ID
write_users(Con,#dialogue{}=Dialogue, Nicks)->
  DU_Set = name_gen:gen_dialogue_user_name(Dialogue),
  lists:map(
  fun(Nick)->
    eredis:q(Con,["SADD",DU_Set, Nick])
  end,
  Nicks).

rewrite_messages(Con, #dialogue{}=Dialogue, M_ListJSON)->
  DM_Tree = name_gen:gen_dialogue_message_name(Dialogue),
  %%Удалить дерево сообщений
  DEL_TREE_RES=eredis:q(Con,["DEL",DM_Tree]),
  io:format("TRACE redis:rewrite_messages/3 Message-tree ~p deleted.~n",[DM_Tree]),
  {ok,_}=DEL_TREE_RES,
  %%Функция записи обновлённого дерева сообщений
  Fun =
    fun(MJSON)->
      M=?json_to_record(message,MJSON),
      #message{timeSending = TIME,id = MID}=M,
      eredis:q(Con,["ZADD",DM_Tree,TIME,MID]),
      io:format("TRACE redis:rewrite_messages/3 Message #~p added to tree.~n",[MID])
    end,
  lists:map(Fun,M_ListJSON).