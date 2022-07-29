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
-export([read/1]).

%%create_table()->
%%  mnesia:create_table(message,
%%    [
%%      {record_name, message},
%%      {type, set},
%%      {attributes, record_info(fields, message)},
%%      {disc_copies, [node()]}
%%    ]).

read(ID)->
  mnesia:read(message,ID).
