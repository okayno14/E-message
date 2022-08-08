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

%% API
-export([write/2,
        read/2,
        read_by_user/2,
        fetch_messages/2,
        update/2,
        delete/2]).

%%записать пользователей
%%записать метаданные диалога
write(Con,#dialogue{users = Nicks} = Dialogue)->
  {ok, DID} = eredis:q(Con,["INCR", "SeqDial"]),
  %%Специально зануляю коллекцию ников, так как эта информация будет храниться в множестве
  Commited = Dialogue#dialogue{id=DID, users = undefined},

  eredis:q(Con,["MULTI"]),
    {ok,_} = eredis:q(Con,["HSET",atom_to_list(dialogue),DID,?record_to_json(dialogue,Commited)]),
    write_users(Con, Commited, Nicks),
  {ok,_}=eredis:q(Con,["EXEC"]),

  Dialogue#dialogue{id = binary_to_integer(DID)}.

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
      [Dialogue#dialogue{users = Users, messages=Messages}]
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

%%надо потестить
fetch_messages(Con,#dialogue{messages = Messages})->
  Fun=
    fun(MID,Res)->
      {ok, M}=eredis:q(Con,["HGET", atom_to_list(message),MID]),
      [?json_to_record(message,M)|Res]
    end,
  lists:foldl(Fun,[],Messages).

%%переписать сообщения ok
%%переписать пользователей ok
update(Con,#dialogue{users = Nicks, id=DID}=Dialogue)->
  %%Получить сообщения
  M_List = fetch_messages(Con,Dialogue),
  io:format("TRACE redis:dialogue/2 M_List: ~p~n",[M_List]),
  eredis:q(Con,["MULTI"]),
    %%пересоздать дерево сообщений
    rewrite_messages(Con,Dialogue,M_List),
    %%Переписать множество пользователей
    eredis:q(Con,["DEL",name_gen:gen_dialogue_user_name(Dialogue)]),
    write_users(Con,Dialogue,Nicks),
    %%Переписать метаданные диалога
    Commited = Dialogue#dialogue{id=DID, users = undefined},
    {ok,_} = eredis:q(Con,["HSET",atom_to_list(dialogue),DID,?record_to_json(dialogue,Commited)]),
  {ok,_}=eredis:q(Con,["EXEC"]),
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

%%DID - бинарная строка, в которой записан численный ID
write_users(Con,#dialogue{}=Dialogue, Nicks)->
  DU_Set = name_gen:gen_dialogue_user_name(Dialogue),
  lists:map(
  fun(Nick)->
    eredis:q(Con,["SADD",DU_Set, Nick])
  end,
  Nicks).

rewrite_messages(Con, #dialogue{}=Dialogue, M_List)->
  DM_Tree = name_gen:gen_dialogue_message_name(Dialogue),
  io:format("TRACE redis:rewrite_messages/3 DM_Tree: ~p~n",[DM_Tree]),
  %%Удалить дерево сообщений
  DEL_TREE_RES=eredis:q(Con,["DEL",DM_Tree]),
  io:format("TRACE redis:dialogue/2 DEL_TREE_RES: ~p~n",[DEL_TREE_RES]),
  {ok,_}=DEL_TREE_RES,
  Fun =
    fun(M_JSON)->
      M=?json_to_record(message,M_JSON),
      #message{timeSending = TIME,id = MID}=M,
      eredis:q(Con,["ZADD",DM_Tree,TIME,MID])
    end,
  %%Создать новое дерево сообщений
  lists:map(Fun,M_List).