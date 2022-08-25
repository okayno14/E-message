%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. июль 2022 18:21
%%%-------------------------------------------------------------------
-module(dialogue_repo).
-include_lib("e_message/include/entity.hrl").
-export([write/2,
        read/2,
        read_by_User/2,
        fetch_messages/2,
        update/2,
        delete/2]).

%%create-операции должны возвращать 1 персистентный объект
%%read-операции - фильтры, поэтому они возвращают пустой или заполненный список
%%update-операции - возвращают новый объект
%%delete - ok
%%ошибка - {error, Reason}

%%Если произошла ошибка соединения с источником -> значит, что вся система становится бесполезной->
%%ошибка критическая и должна быть послана на самый верх

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