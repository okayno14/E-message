%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. июль 2022 18:21
%%%-------------------------------------------------------------------
-module(dialogue_repo).
-include("entity.hrl").

%% API
-export([create_table/0,write/1,read/1, read_by_User/1]).

create_table()->
  mnesia:create_table(dialogue,
    [
      {record_name, dialogue},
      {type, set},
      {attributes, record_info(fields, dialogue)},
      {index,[name,users]},
      {disc_copies, [node()]}
    ]).

write(Dialogue)->
  ID = seq:get_counter(seq),
  io:format("ID=~w~n",[ID]),
  Commited = Dialogue#dialogue{id=ID},
  io:format("Commited Dialogue: ~p~n",[Commited]),
  mnesia:transaction(fun()->mnesia:write(Commited)end).

read(ID)->
  Transaction = mnesia:transaction(fun()-> mnesia:read(dialogue,ID) end),
  case Transaction of
    {atomic, [Dialogue|_]}->Dialogue;
    {atomic, []}->{error, not_found};
    {aborted, _Reason}-> {error, _Reason}
  end.

read_by_User(User)->
  Transaction = mnesia:transaction(
    fun()->
      mnesia:foldl(
        fun(Dialogue, Res)->
          case dialogue_service:containsUser(Dialogue,User) of
            true->
              [Dialogue|Res];
            _->
              Res
          end
        end,
        [],
        dialogue)
    end),
  case Transaction of
    {atomic,[]}->{error, not_found};
    {atomic,_Arr}->_Arr;
    {aborted,_Reason}->{error,_Reason}
  end.

update(DialogueNew)->
  mnesia:transaction( fun()-> mnesia:write(DialogueNew) end).

%%Каскадно удаляет все сообшения из диалога, т.к. сообщения вне диалога не имеют смысла
delete(#dialogue{messages = Messages}=Dialogue)->
  mnesia:transaction(
    fun()->
      %%lists:map(fun(M)->mnesia:delete({message,M}) end,Messages),
      mnesia:delete({dialogue,Dialogue})
    end).