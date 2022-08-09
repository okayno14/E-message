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
-export([read/2,
        write/2,
        update/2,
        delete/2]).

%%create-операции должны возвращать 1 персистентный объект
%%read-операции - фильтры, поэтому они возвращают пустой или заполненный список
%%update-операции - возвращают новый объект
%%delete - ok
%%ошибка - {error, Reason}

%%Если произошла ошибка соединения с источником -> значит, что вся система становится бесполезной->
%%ошибка критическая и должна быть послана на самый верх

write(Message, Con)->
  redis_message:write(Con,Message).

read(ID, Con)->
  redis_message:read(Con,ID).

update(Message, Con)->
  redis_message:update(Con,Message).

%%Каскадно удаляются артефакты, так как вне сообщений они не имеют смысла
delete(#message{}=Message, Con)->
  redis_message:delete(Con,Message).
