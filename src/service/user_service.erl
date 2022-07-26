%%%-------------------------------------------------------------------
%%% @author aleksandr_work
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. июль 2022 13:01
%%%-------------------------------------------------------------------
-module(user_service).
-include_lib("e_message/include/entity.hrl").


%% API
-export([create_user/2,
          get_user/3,
          delete_user/2]).

create_user(User, Con)->
  F=
    fun()->
      user_repo:write(User, Con)
    end,
  redis_transaction:begin_transaction(F).

get_user(Nick,Pass, Con)->
  F=
    fun()->
      user_repo:read(Nick,Pass, Con)
    end,
  T= redis_transaction:begin_transaction(F),
  service:extract_single_value(T).

delete_user(User, Con)->
    F=
    fun()->
      user_repo:delete(User, Con),
      ok
    end,
  redis_transaction:begin_transaction(F).