-module(dialogue_validation_service).

-include_lib("e_message/include/entity.hrl").

-compile(export_all).

all()->
	[fun(X)-> is_id_valid(X) end,
		fun(X)-> is_name_valid(X) end,
		fun(X)-> is_users_valid(X) end,
		fun(X)-> is_messages_valid(X) end].

is_id_valid(ID) when is_integer(ID)->
	true;
is_id_valid(_)->
	false.

is_name_valid(Name) when is_binary(Name) ->
	P = binary_to_list(Name),
	case re:run(P,"[a-zA-z0-9]+") of
		nomatch-> 
			false;
		{match, [H|_]}->	
			if 
				element(2,H) =:= length(P)->
					true;
				element(2,H) =/= length(P)->
					false
			end
	end;
is_name_valid(_)->
	false.

is_users_valid(Users) when is_list(Users)->
	%валидируем каждый ник списка
	F = fun(Elem,Res)-> 
			Buf = common_validation_service:is_field_valid(#user{nick=Elem},
															user_validation_service:all(),
															#user.nick),
			Res and Buf
		end,
	lists:foldl(F,true,Users);
is_users_valid(_)->
	false.

is_messages_valid(Messages) when is_list(Messages)->
	%валидируем каждый id в массиве
	F = fun(Elem,Res)->
			Res and is_id_valid(Elem)
		end,
	lists:foldl(F,true,Messages);
is_messages_valid(_)->
	false.