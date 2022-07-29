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
-export([create_table/0,get_counter/1,init/0]).

create_table()->
  mnesia:create_table(seq,
    [
      {record_name, seq},
      {type, set},
      {attributes, record_info(fields, seq)},
      {disc_copies, [node()]}
    ]).

init()->
    F=fun()->
      mnesia:write(#seq{table_name = dialogue,counter =  0}),
      mnesia:write(#seq{table_name = message,counter =  0})
    end,
    transaction:begin_transaction(F).

get_counter(Entity)->
  mnesia:dirty_update_counter(seq,Entity,1).