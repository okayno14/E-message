%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. авг. 2022 10:21
%%%-------------------------------------------------------------------
-module(redis_artifact).
-author("aleksandr_work").
-export([]).

%% на вход всегда принимаются:
%%     дескриптор соединения, сущность
%%     дескриптор соединения, ключи поиска

%%create-операции должны возвращать 1 персистентный объект
%%read-операции - фильтры, поэтому они возвращают пустой или заполненный список
%%update-операции - возвращают новый объект
%%delete - ok