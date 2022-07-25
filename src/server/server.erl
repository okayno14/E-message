%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. июль 2022 11:23
%%%-------------------------------------------------------------------
-module(server).
-author("aleksandr_work").

%% API
-export([start/0]).

start() ->
  case  gen_tcp:listen(1234,[{active, false}]) of
    {ok, _ListenSocket}->start_servers(8);
    {error, Reason}->io:format("Error, can't listen port ~w~n", [Reason])
  end.

start_servers(Num)-> io:format("~w Acceptors will spawn~n",[Num]).