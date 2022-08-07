%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. авг. 2022 20:53
%%%-------------------------------------------------------------------
-module(name_gen).
-include("entity.hrl").

%% API
-export([gen_dialogue_user_name/1]).

gen_dialogue_user_name(#dialogue{id = DID}) when is_binary(DID)->
  _B=[":"|atom_to_list(user)],
  [atom_to_list(dialogue)|[":"|[parseID(DID) |_B]]].

parseID(ID) when is_binary(ID)->
  binary_to_list(ID);
parseID(ID) when is_integer(ID)->
  integer_to_list(ID);
parseID(ID) when is_list(ID)->
  ID.
