%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 31. июль 2022 15:06
%%%-------------------------------------------------------------------
-module(message).
-include("entity.hrl").

%% API
-export([change_state/1]).

change_state(#message{state = State}=M)->
  case State of
    written->M#message{state = sent};
    sent->M#message{state = read}
  end.
