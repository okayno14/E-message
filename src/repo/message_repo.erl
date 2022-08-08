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
-export([create_table/0,
        read/2,
        write/2,
        update/2,
        delete/2]).

create_table()->
  mnesia:create_table(message,
    [
      {record_name, message},
      {type, set},
      {attributes, record_info(fields, message)},
      {disc_copies, [node()]}
    ]).

write(Message, Con)->
  redis_message:write(Con,Message).

read(ID, Con)->
  redis_message:read(Con,ID).

update(Message, Con)->
  redis_message:update(Con,Message).

%%Каскадно удаляются артефакты, так как вне сообщений они не имеют смысла
delete(#message{}=Message, Con)->
  redis_message:delete(Con,Message).
