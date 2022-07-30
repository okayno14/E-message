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
-export([containsUser/2,create_dialogue/1,get_dialogues/1,delete_dialogue/1,quit_dialogue/2]).

create_dialogue(D)->
  F=
    fun()->
      dialogue_repo:write(D)
    end,
  transaction:begin_transaction(F).

%%get_dialogue(ID)->
%%  Fun =
%%    fun()->
%%      dialogue_repo:read(ID)
%%    end,
%%  Transaction = transaction:begin_transaction(Fun),
%%  case Transaction of
%%
%%  end

get_dialogues(U)->
  F=
    fun()->
      dialogue_repo:read_by_User(U)
    end,
  service:extract_values(transaction:begin_transaction(F)).

containsUser(#dialogue{users = Users}=_Dialogue, #user{nick = Nick2}=_User) ->
  lists:any(fun(Nick)->Nick=:=Nick2 end,Users).

quit_dialogue(#dialogue{users = Nick_List}=D,#user{nick = Nick}=U)->
  case containsUser(D,U) of
    true->
      if
        length(Nick_List) =:= 1 ->
          delete_dialogue(D);
        length(Nick_List) >1 ->
          Arr = lists:filter(fun(Elem)-> Elem =/= Nick end, Nick_List),
          D1=D#dialogue{users = Arr},
          Fun=fun()-> dialogue_repo:update(D1) end,
          case transaction:begin_transaction(Fun) of
            {error,_R}->{error,_R};
            ok->D1
          end
      end;
    false->{error,user_not_found_in_dialogue}
  end.

delete_dialogue(D)->
  F=fun()->
      dialogue_repo:delete(D)
    end,
  transaction:begin_transaction(F).