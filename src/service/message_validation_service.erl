-module(message_validation_service).

-include_lib("e_message/include/entity.hrl").

-compile(export_all).

all()->
	[fun(X)-> is_id_valid(X) end,
		fun(X)-> is_from_valid(X) end,
		fun(X)-> is_time_valid(X) end,
		fun(X)-> is_text_valid(X) end,
		fun(X)-> is_state_valid(X) end,
		fun(X)-> is_artifactID_valid(X) end].

is_id_valid(ID) when is_integer(ID)->
	true;
is_id_valid(_)->
	false.

is_from_valid(From)->
	common_validation_service:is_field_valid(From,
												user_validation_service:all(),
												#user.nick).

is_time_valid(Time) when is_integer(Time) ->
	true;
is_time_valid(_) ->
	false.

is_text_valid(Text) when is_binary(Text) and (byte_size(Text)>0) ->
	true;
is_text_valid(_)->
	false.

is_state_valid(State) when is_atom(State) ->
	true;
is_state_valid(_)->
	false.

is_artifactID_valid(artifactID) when is_integer(artifactID)->
	true;
is_artifactID_valid(_)->
	false.