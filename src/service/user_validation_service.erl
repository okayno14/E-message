-module(user_validation_service).

-compile(export_all).

all()->
	[
		fun(X)->is_nick_valid(X) end,
		fun(X)->is_password_valid(X) end	
	].

is_password_valid(Pass)->
	P = binary_to_list(Pass),
	case re:run(P,"^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[@!\\#$%^&+=])(?=[^\r\n\t\f\v ]+$).{8,}$") of
		nomatch-> 
			false;
		{match, [H|_]}->
			if 
				element(2,H) =:= length(P)->
					true;
				element(2,H) =/= length(P)->
					false
			end
	end.

is_nick_valid(Nick)->
	P = binary_to_list(Nick),
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
	end.