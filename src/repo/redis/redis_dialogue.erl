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
        read_by_user/2]).

%%записать пользователей
write(Con,#dialogue{users = Nicks} = Dialogue)->
  {ok, DID} = eredis:q(Con,["INCR", "SeqDial"]),
  %%Специально зануляю коллекцию ников, так как эта информация будет храниться в множестве
  Commited = Dialogue#dialogue{id=DID, users = undefined},
  {ok,_} = eredis:q(Con,["HSET",atom_to_list(dialogue),DID,?record_to_json(dialogue,Commited)]),
  write_users(Con, Commited, Nicks),
  Dialogue#dialogue{id = binary_to_integer(DID)}.

%%прочитать пользователей ok
%%прочитать сообщения
read(Con, DID) when is_integer(DID)->
  {ok, T} = eredis:q(Con,["HGET",atom_to_list(dialogue),DID]),
  case T of
    undefined->[];
    JSON ->
      Dialogue = ?json_to_record(dialogue,JSON),
      {ok,Users} = eredis:q(Con,["SMEMBERS", name_gen:gen_dialogue_user_name(Dialogue)]),
      {ok,Messages} = eredis:q(Con,["ZRANGE",name_gen:gen_dialogue_message_name(Dialogue),0,-1]),
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


%%zrange dialogue:<DID>:message 0 -1
%%fetch_messages


%%переписать сообщения
%%переписать пользователей

%%update(Con, Dialogue)->
%%  %%message_write
%%


%%DID - бинарная строка, в которой записан численный ID
write_users(Con,#dialogue{}=Dialogue, Nicks)->
  eredis:q(Con,["MULTI"]),
  lists:map(
  fun(Nick)->
    eredis:q(Con,["SADD", name_gen:gen_dialogue_user_name(Dialogue), Nick])
  end,
  Nicks),
  {ok,_} = eredis:q(Con,["EXEC"]).


