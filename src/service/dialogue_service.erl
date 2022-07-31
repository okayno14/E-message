%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. июль 2022 0:13
%%%-------------------------------------------------------------------
-module(dialogue_service).
-include("entity.hrl").

%% API
-export([create_dialogue/1,
        get_dialogue/1,
        get_dialogues/1,
        quit_dialogue/2,
        get_message/1,
        get_messages/1,
        add_message/2,
        delete_dialogue/1]).

create_dialogue(D)->
  F=
    fun()->
      dialogue_repo:write(D)
    end,
  transaction:begin_transaction(F).

get_dialogue(ID)->
  Fun =
    fun()->
      dialogue_repo:read(ID)
    end,
  Transaction = transaction:begin_transaction(Fun),
  io:format("TRACE dialogue_service:get_dialogue/1 Transaction:~p~n",[Transaction]),
  service:extract_single_value(Transaction).

get_dialogues(U)->
  F=
    fun()->
      dialogue_repo:read_by_User(U)
    end,
  service:extract_values(transaction:begin_transaction(F)).

get_message(MID)->
  F=
  fun()->
    message_repo:read(MID)
  end,
  service:extract_single_value(transaction:begin_transaction(F)).

get_messages(D)->
  F=
  fun()->
    dialogue_repo:fetch_messages(D)
  end,
  service:extract_values(transaction:begin_transaction(F)).

quit_dialogue(#dialogue{users = Nick_List}=D,#user{nick = Nick}=U)->
  case dialogue:containsUser(D,U) of
    true->
      io:format("TRACE dialogue_service:quit_dialogue/2 User contains in dialogue~n"),
      if
        length(Nick_List) =:= 1 ->
          T=delete_dialogue(D),
          io:format("TRACE dialogue_service:quit_dialogue/2 Delete transaction:~p~n",[T]),
          T;
        length(Nick_List) >1 ->
          Arr = lists:filter(fun(Elem)-> Elem =/= Nick end, Nick_List),
          D1=D#dialogue{users = Arr},
          Fun=fun()-> dialogue_repo:update(D1) end,
          T1=transaction:begin_transaction(Fun),
          io:format("TRACE dialogue_service:quit_dialogue/2 Update transaction:~p~n",[T1]),
          T1
      end;
    false->
      {error,user_not_found_in_dialogue}
  end.

%%Сохранить в БД сообщение
%%Добавить полученный ID в диалог
%%Сохранить диалог
%%Вовзращает персистентное сообщение
add_message(D,M)->
  Fun=
    fun()->
      M_Persisted = message_repo:write(M),
      D_Updated = dialogue:add_message(D,M_Persisted),
      dialogue_repo:update(D_Updated),
      message_repo:update(message:change_state(M_Persisted)),
      message_repo:read(M_Persisted#message.id)
    end,
  T = transaction:begin_transaction(Fun),
  service:extract_single_value(T).

delete_dialogue(D)->
  F=fun()->
      dialogue_repo:delete(D)
    end,
  transaction:begin_transaction(F).