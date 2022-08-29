%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. июль 2022 0:13
%%%-------------------------------------------------------------------
-module(dialogue_service).
-include_lib("e_message/include/entity.hrl").

%% API
-export([create_dialogue/2,
        get_dialogue/2,
        get_dialogues/2,
        quit_dialogue/3,
        get_message/4,
        get_messages/3,
        add_message/3,
        read_message/4,
        change_text/3,
        delete_message/4,
        delete_dialogue/2]).

create_dialogue(#dialogue{users=Users} = D, Con)->
  case is_users_exists(Users,true,Con) of
    true->
      F=
        fun()->
          dialogue_repo:write(D, Con)
        end,
      redis_transaction:begin_transaction(F);
    false->
      {error, users_doesnt_exists}
  end.

is_users_exists([Nick|Tail],true,Con)->
  F = fun()->user_repo:read(Nick,Con) end,
  case transaction:begin_transaction(F) of
    {error,_}->
      is_users_exists(Tail,false,Con);
    []->
      is_users_exists(Tail,false,Con);
    _U->
      is_users_exists(Tail,true,Con)
  end;
is_users_exists([_Nick|_Tail],false,_)->
  false;
is_users_exists([],Res,_)->
  Res.

get_dialogue(ID, Con)->
  Fun =
    fun()->
      dialogue_repo:read(ID, Con)
    end,
  Transaction = redis_transaction:begin_transaction(Fun),
  io:format("TRACE dialogue_service:get_dialogue/1 Transaction:~p~n",[Transaction]),
  service:extract_single_value(Transaction).

get_dialogues(U, Con)->
  F=
    fun()->
      dialogue_repo:read_by_User(U, Con)
    end,
  service:extract_multiple_values(redis_transaction:begin_transaction(F)).

get_message(U,MID,DID,Con)->
  F=
    fun()->
      message_repo:read(MID, Con)
    end,
  F1 = 
    fun()->
      dialogue_repo:read(DID,Con) 
    end,
  M = service:extract_single_value(redis_transaction:begin_transaction(F)),
  D = service:extract_single_value(transaction:begin_transaction(F1)),
  io:format("TRACE dialogue_service:get_message/4 M:~p~n",[M]),
  io:format("TRACE dialogue_service:get_message/4 D:~p~n",[D]),
  if 
    (element(1,D) =:= error) or (element(1,M)=:=error) ->
      %один из запрошенных объектов не был найден
      {error,not_found};
    true->
      %условие ошибки не сработало, следовательно, пробуем вернуть клиенту сообщение
      case dialogue:is_sender_or_receiver(U,M,D) of
        true->
          M;
        false->
          {error,not_authorised}
      end
  end.
  
get_messages(User,D,Con)->
  case dialogue:containsUser(D,User) of
    true->
      F=
        fun()->
          dialogue_repo:fetch_messages(D, Con)
        end,
      service:extract_multiple_values(redis_transaction:begin_transaction(F));
    false->
      {error,not_authorised}
  end.

quit_dialogue(#dialogue{users = Nick_List}=D,#user{nick = Nick}=U, Con)->
  case dialogue:containsUser(D,U) of
    true->
      io:format("TRACE dialogue_service:quit_dialogue/2 User contains in dialogue~n"),
      if
        %%диалог нужно удалить
        length(Nick_List) =:= 1 ->
          T=delete_dialogue(D, Con),
          io:format("TRACE dialogue_service:quit_dialogue/2 Delete transaction:~p~n",[T]),
          ok;
        %%из диалога просто убирается 1 участник
        length(Nick_List) >1 ->
          Arr = lists:filter(fun(Elem)-> Elem =/= Nick end, Nick_List),
          D1=D#dialogue{users = Arr},
          Fun=fun()-> dialogue_repo:update(D1, Con) end,
          T1=redis_transaction:begin_transaction(Fun),
          io:format("TRACE dialogue_service:quit_dialogue/2 Update transaction:~p~n",[T1]),
          T1
      end;
    false->
      {error,user_not_found_in_dialogue}
  end.

add_message(D,#message{from = From}=M,Con)->
  case dialogue:containsUser(D,#user{nick=From}) of 
    true->
      Fun=
        fun()->
          M_Persisted = message_repo:write(message:send(M), Con),
          D_Updated = dialogue:add_message(D,M_Persisted),
          dialogue_repo:update(D_Updated, Con),
          [M_Persisted]
        end,
      T = redis_transaction:begin_transaction(Fun),
      service:extract_single_value(T);
    false->
      {error,user_not_found_in_dialogue}
  end.

read_message(#user{nick=Nick}=U,#message{from=From}=M,D,Con)->
  case dialogue:containsUser(D,U) of
    true when Nick =/= From->
      case message:read(M) of
        {error,_R}->{error,_R};
        M_Persisted->
          message_repo:update(M_Persisted, Con)
      end;
    true when Nick =:= From->
      {error,sender_read_message};
    false->
      {error,not_authorised}
  end.

change_text(M,Text, Con)->
  Fun=
  fun()->
    M_Persited = M#message{text = Text},
    message_repo:update(M_Persited, Con),
    [M_Persited]
  end,
  T= redis_transaction:begin_transaction(Fun),
  service:extract_single_value(T).

delete_message(#dialogue{messages = MessageIDS}=D,
              #message{id = MID,from = Nick}=M,
              #user{nick = Nick},
              Con)->
  F=
    fun()->
      MessageIDS_F=lists:filter(fun(ID)-> ID =/= MID end, MessageIDS),
      io:format("TRACE dialogue_service:delete_message/2 MessageIDS_F: ~p~n",[MessageIDS_F]),
      dialogue_repo:update(D#dialogue{messages = MessageIDS_F}, Con),
      message_repo:delete(M, Con)
    end,
  redis_transaction:begin_transaction(F);

delete_message(_D,
              #message{from = _Nick1},
              #user{nick = _Nick2},
              _)->
  {error,no_right_for_operation}.

delete_dialogue(D, Con)->
  F=fun()->
      dialogue_repo:delete(D, Con)
    end,
  redis_transaction:begin_transaction(F).