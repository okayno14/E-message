%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. июль 2022 15:06
%%%-------------------------------------------------------------------
-module(message).
-include_lib("e_message/include/entity.hrl").

%% API
-export([read/1,send/1]).

%%КА:
%% символы входного алфавита - функции ЯП
%% состояния - поле записи
%% отображение входа, состояния на новое состояние - функции ЯП

read(#message{state = sent}=M)->
  M#message{state = read};
read(#message{state = _})->
  {error,not_allowed_for_current_state}.

send(#message{state=written}=M)->
  M#message{state = sent};
send(#message{state = _})->
  {error,not_allowed_for_current_state}.