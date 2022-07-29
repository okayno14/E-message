%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. июль 2022 18:21
%%%-------------------------------------------------------------------
-module(message_repo).
-include("entity.hrl").

%% API
-export([create_table/0, read/1, write/1,update/1,delete/1]).

create_table()->
  mnesia:create_table(message,
    [
      {record_name, message},
      {type, set},
      {attributes, record_info(fields, message)},
      {disc_copies, [node()]}
    ]).

write(Message)->
  ID = seq:get_counter(seq),
  Commited=Message#message{id=ID},
  mnesia:write(Commited),
  mnesia:read(message,ID).

read(ID)->
  mnesia:read(message,ID).

update(Message)->
  mnesia:write(Message).

%%Каскадно удаляются артефакты, так как вне сообщений они не имеют смысла
delete(ID)->
  mnesia:delete({message,ID}).
