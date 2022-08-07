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
-export([gen_dialogue_user_name/1,
        gen_dialogue_message_name/1,
        gen_dialogue_user_search_pattern/0,
        parse_DID_from_dialogue_user_search_pattern/1]).

%%dialogue:<DID>:user
gen_dialogue_user_name(#dialogue{id = DID})->
  _B=[":"|atom_to_list(user)],
  [atom_to_list(dialogue)|[":"|[parseID(DID) |_B]]].

%%dialogue:<DID>:message
gen_dialogue_message_name(#dialogue{id = DID})->
  _B=[":"|atom_to_list(message)],
  [atom_to_list(dialogue)|[":"|[parseID(DID)|_B]]].

%%dialogue:*:user
gen_dialogue_user_search_pattern()->
  [atom_to_list(dialogue)|[":"|atom_to_list(user)]].

parse_DID_from_dialogue_user_search_pattern(Query)->
  parse_DID_from_dialogue_user_search_pattern(Query,1).

parse_DID_from_dialogue_user_search_pattern(Query, _State=1)->
  case string:split(Query,atom_to_list(dialogue)) of
    [Query|_]->{error,not_found};
    [_|Rest]->parse_DID_from_dialogue_user_search_pattern(Rest,2)
  end;
parse_DID_from_dialogue_user_search_pattern(Query,_State=2)->
  case string:split(Query,":") of
    Query->{error,not_found};
    [_|Rest]->parse_DID_from_dialogue_user_search_pattern(Rest,3)
  end;
parse_DID_from_dialogue_user_search_pattern(Query,_State=3)->
  case string:split(Query,":") of
    Query->{error,not_found};
    [Res|_]->
      case string:to_integer(Res) of
        {error,_}->{error,not_found};
        {Num,_}->Num
      end
  end.

parseID(ID) when is_binary(ID)->
  binary_to_list(ID);
parseID(ID) when is_integer(ID)->
  integer_to_list(ID);
parseID(ID) when is_list(ID)->
  ID.
