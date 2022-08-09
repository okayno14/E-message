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
-export([gen_dialogue_user_name/1,
        gen_dialogue_message_name/1,
        gen_dialogue_user_search_pattern/0,
        parse_DID_from_dialogue_message/1]).

%%Вспомогательный модуль для работы с ключами Redis

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
  [atom_to_list(dialogue)|[":*:"|atom_to_list(user)]].

%%КА для парсинга DID из строки:
%%слова входного алфавита: извлекаются из Query - анализируемой строки
%%состояние: входная целочисленная переменная State
%%отображение входного слова на состояние: функция ЯП.
%%выход: возвращаемое функцией значение
%%начальное состояние: 1
parse_DID_from_dialogue_message(Query)->
  parse_DID_from_dialogue_message(Query,1).

parse_DID_from_dialogue_message(Query, _State=1)->
  case string:split(Query,atom_to_list(dialogue)) of
    [Query|_]->{error,not_found};
    [_|Rest]-> parse_DID_from_dialogue_message(Rest,2)
  end;
parse_DID_from_dialogue_message(Query,_State=2)->
  case string:split(Query,":") of
    Query->{error,not_found};
    [_|Rest]-> parse_DID_from_dialogue_message(Rest,3)
  end;
parse_DID_from_dialogue_message(Query,_State=3)->
  case string:split(Query,":") of
    Query->{error,not_found};
    [Res|_]->
      case string:to_integer(Res) of
        {error,_}->{error,not_found};
        {Num,_}->{ok,Num}
      end
  end.

parseID(ID) when is_binary(ID)->
  binary_to_list(ID);
parseID(ID) when is_integer(ID)->
  integer_to_list(ID);
parseID(ID) when is_list(ID)->
  ID.
