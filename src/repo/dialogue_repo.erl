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
-export([create_table/0,
        write/2,
        read/2,
        read_by_User/2,
        fetch_messages/2,
        update/2,
        delete/2]).

create_table()->
  mnesia:create_table(dialogue,
    [
      {record_name, dialogue},
      {type, set},
      {attributes, record_info(fields, dialogue)},
      {index,[name,users]},
      {disc_copies, [node()]}
    ]).

write(Dialogue, Con)->
  redis_dialogue:write(Con,Dialogue).

read(ID, Con)->
  redis_dialogue:read(Con,ID).

read_by_User(User, Con)->
  redis_dialogue:read_by_user(Con,User).

fetch_messages(#dialogue{}=D, Con)->
  redis_dialogue:fetch_messages(Con,D).

update(DialogueNew, Con)->
  redis_dialogue:update(Con,DialogueNew).

delete(#dialogue{}=Dialogue, Con)->
  redis_dialogue:delete(Con,Dialogue).