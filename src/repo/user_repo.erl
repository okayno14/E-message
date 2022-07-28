%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. июль 2022 18:21
%%%-------------------------------------------------------------------
-module(user_repo).
-include("entity.hrl").

%% API
-export([create_table/0,write/1,read/1,read/2,update/1,delete/1]).

create_table()->
  mnesia:create_table(user,
    [
      {record_name, user},
      {type, set},
      {attributes, record_info(fields,user)},
      {disc_copies, [node()]}
    ]).

write(User)->
  case read(User#user.nick) of
    {error,not_found}->mnesia:transaction(fun()-> mnesia:write(User) end);
    User->{error, user_already_exists};
    {error,_Reason}->{error,_Reason}
  end.

read(Nick)->
  Transaction = mnesia:transaction(fun()-> mnesia:read(user,Nick) end),
  case Transaction of
    {atomic,[User|_]}->User;
    {atomic,[]}->{error,not_found};
    {aborted, _Reason}->{error,_Reason}
  end.

read(Nick,Pass)->
  case read(Nick) of
    User when User#user.pass =:= Pass -> User;
    {error,_Reason}->{error,_Reason};
    _->{error,not_found}
  end.

update(UserNew) ->
  mnesia:transaction(fun()-> mnesia:write(UserNew) end).

delete(User) ->
  Nick = User#user.nick,
  io:format("~p~n",[Nick]),
  mnesia:transaction(fun()-> mnesia:delete({user,Nick}) end).