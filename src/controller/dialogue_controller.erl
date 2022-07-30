%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. июль 2022 10:40
%%%-------------------------------------------------------------------
-module(dialogue_controller).
-include("entity.hrl").

%% API
-export([create_dialogue/1]).

create_dialogue(Dialogue)->
  dialogue_service:create_dialogue(Dialogue).
