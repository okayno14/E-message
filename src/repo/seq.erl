%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. июль 2022 18:54
%%%-------------------------------------------------------------------
-module(seq).
-include("entity.hrl").

%% API
-export([create_table/0,get_counter/1]).

create_table()->
  mnesia:create_table(seq,
    [
      {record_name, seq},
      {type, set},
      {attributes, record_info(fields, seq)},
      {disc_copies, [node()]}
    ]).

get_counter(Entity)->
  mnesia:dirty_update_counter(seq,Entity,1).