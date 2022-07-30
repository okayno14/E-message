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
-export([create_table/0,write/1,read/1, read_by_User/1, fetch_messages/1, update/1, delete/1]).

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
  Commited = Dialogue#dialogue{id=ID},
  mnesia:write(Commited),
  [Obj|_]=mnesia:read(dialogue,ID),
  Obj.

read(ID)->
  mnesia:read(dialogue,ID).

read_by_User(User)->
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
    dialogue).

fetch_messages(Messages)->
  lists:foldl(
    fun(MID,Res)->
      case message_repo:read(MID) of
        [] -> Res;
        M -> [M|Res]
      end
    end, [], Messages).


update(DialogueNew)->
  mnesia:write(DialogueNew).

%%Каскадно удаляет все сообшения из диалога, т.к. сообщения вне диалога не имеют смысла
delete(#dialogue{messages = Messages}=Dialogue)->
  lists:map(fun(M)->message_repo:delete(M) end, Messages),
  mnesia:delete({dialogue,Dialogue}).
