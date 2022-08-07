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
        read/2]).

%%записать пользователей
write(Con,#dialogue{users = Nicks} = Dialogue)->
  {ok, DID} = eredis:q(Con,["INCR", "SeqDial"]),
  %%Специально зануляю коллекцию ников, так как эта информация будет храниться в множестве
  Commited = Dialogue#dialogue{id=DID, users = undefined},
  {ok,_} = eredis:q(Con,["HSET",atom_to_list(dialogue),DID,?record_to_json(dialogue,Commited)]),
  write_users(Con, Commited, Nicks),
  Dialogue#dialogue{id = binary_to_integer(DID)}.

%%прочитать пользователей
%%прочитать сообщения
read(Con, DID)->
  {ok, T} = eredis:q(Con,["HGET",atom_to_list(dialogue),DID]),
  case T of
    undefined->[];
    _ ->
      [?json_to_record(dialogue,T)]
  end.

%%переписать сообщения
%%переписать пользователей

%%update(Con, Dialogue)->
%%  %%message_write
%%


%%DID - бинарная строка, в которой записан численный ID
write_users(Con,#dialogue{id=DID}, Nicks)->
  eredis:q(Con,["MULTI"]),
  _B=[":"|atom_to_list(user)],
  Str=[atom_to_list(dialogue)|[":"|[DID |_B]]],
  io:format("~p~n",[Str]),
  lists:map(
  fun(Nick)->
    eredis:q(Con,["SADD", Str, Nick])
  end,
  Nicks),
  {ok,_} = eredis:q(Con,["EXEC"]).
