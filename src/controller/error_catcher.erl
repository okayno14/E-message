-module(error_catcher).

-export([handle/1]).

handle({error,_}=Err)->
	throw(Err);
handle(Data)->
	Data.