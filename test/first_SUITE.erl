-module(first_SUITE).

-export([all/0]).

-export([foo/1]).

all()->
	[foo].

foo(_)->
	<<"Vasya">> = ct:get_config(user1).